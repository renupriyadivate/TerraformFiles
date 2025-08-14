terraform {
  backend "s3" {
    bucket         = "terraform-jenkins-pipeline-bucket-eashu"
    key            = "my-first-pipeline/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-baby"
    encrypt        = true
  }
}

resource "aws_vpc" "vpc1" {
   cidr_block = var.cidr_block
   tags = {
      Name = "test-vpc"
   }
}

resource "aws_internet_gateway" "ig1" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "test-ig"
  }
}


data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_subnet" "test_subnets" {
  count = var.subnet_count
  vpc_id = aws_vpc.vpc1.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = cidrsubnet(var.cidr_block,8,count.index + 1)
  map_public_ip_on_launch = true
  tags = {
    Name = "test_public_subnet${count.index + 1}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id

  route  {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.ig1.id
  }
}

# resource "aws_route" "default" {
#   route_table_id = aws_route_table.rt.id
#   gateway_id = aws_internet_gateway.ig1.id
#   destination_cidr_block = "0.0.0.0/0"
# }

resource "aws_route_table_association" "rt" {
  count = var.subnet_count
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.test_subnets[count.index].id
}

resource "tls_private_key" "keyPairs" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "public_key" {
   key_name = "jenkins-key"
   public_key = tls_private_key.keyPairs.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.keyPairs.private_key_pem
  filename = "${path.module}/jenkins-key.pem"
}

resource "aws_security_group" "sg" {
  description = "This security group for creating the security at ec2 level"
  vpc_id = aws_vpc.vpc1.id
  name = "test-sg"

  ingress {
    to_port = 22
    from_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    to_port = 80
    from_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    to_port = 443
    from_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec21" {
  count = var.subnet_count
  instance_type = var.instance_type
  key_name = aws_key_pair.public_key.key_name
  ami = var.ami_value
  vpc_security_group_ids = [ aws_security_group.sg.id ]
  subnet_id = aws_subnet.test_subnets[count.index].id
  tags = {
    Name = "test-ec2_instance_${count.index + 1}"
  }
}

resource "aws_lb_target_group" "name" {
  name = "test-tg"
  vpc_id = aws_vpc.vpc1.id
  port = 80
  protocol = "HTTP"

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    timeout = 5
    interval = 30
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "tg" {
  count = var.subnet_count
  target_id = aws_instance.ec21[count.index].id
  target_group_arn = aws_lb_target_group.name.arn
  port = 80
}

resource "aws_lb" "alb" {
 
  name = "test-lb"
  load_balancer_type = "application"
  subnets =  aws_subnet.test_subnets[*].id 
  security_groups = [ aws_security_group.sg.id ]
  tags = {
    Name = "test-alb"
  }
}

resource "aws_lb_listener" "test-alb" {
   load_balancer_arn = aws_lb.alb.arn
   port = 80
   protocol = "HTTP"
   default_action {
     type = "forward"
     target_group_arn = aws_lb_target_group.name.arn
   }
}

