resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "ig1" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "test_vpc"
  }
}
resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = var.public_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "test_subnet"
  }
}

resource "aws_route_table" "route1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = var.internet_cidr
    gateway_id = aws_internet_gateway.ig1.id
  }
}

resource "aws_route_table_association" "name" {
  route_table_id = aws_route_table.route1.id
  subnet_id = aws_subnet.subnet1.id
}

resource "aws_security_group" "sg1" {
  name = "test_security_rules"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    description = "allow ssh port to login into server"
    to_port = 22
    from_port = 22
    protocol = "tcp"
    cidr_blocks = [var.internet_cidr] 
  }

  ingress {
    description = "allow http port to login into the browser"
    to_port = 80
    from_port = 80
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr]
  }
  ingress {
    description = "allow https request"
    to_port = 443
    from_port = 443
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "test_group"
  }
  
}
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "public_key" {
  key_name  = "terraform-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}

resource "local_file" "private_key" {
  filename   = "ec2_key.pem"
  content    = tls_private_key.key_pair.private_key_pem
  file_permission = "0600"
}



resource "aws_instance" "ec21" {
  ami = var.ami
  key_name = aws_key_pair.public_key.key_name
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.sg1.id]
  associate_public_ip_address = true
  tags = {
    Name = "MyEC2Instance"
  }


  connection {
    type        = "ssh"                          # Define connection type as SSH
    user        = "ubuntu"                       # User for Ubuntu AMI (use "ec2-user" for Amazon Linux)
    private_key = file("./ec2_key.pem")  # Path to your private key file
    host        = aws_instance.ec21.public_ip               # Use the public IP of the instance
  }

  # Step 5: Run commands on the EC2 instance using remote-exec provisioner
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
}
