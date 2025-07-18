resource "aws_vpc" "vpc1" {
  cidr_block = var.cidr
  tags = {
    Name = "test_vpc"
  }
}

resource "aws_internet_gateway" "ig1"{
  vpc_id = aws_vpc.vpc1.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = var.subnet_cidr[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = var.subnet_cidr[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-subnet-2"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc1.id
  
  tags = {
    Name = "public-route"
  }
}

resource "aws_route" "default" {
  route_table_id = aws_route_table.public_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig1.id
}

resource "aws_route_table_association" "rt1" {
  route_table_id = aws_route_table.public_route.id
  subnet_id = aws_subnet.public_subnet1.id
}

resource "aws_route_table_association" "rt2" {
  route_table_id = aws_route_table.public_route.id
  subnet_id = aws_subnet.public_subnet2.id
}

resource "aws_security_group" "sg" {
  name = "test-sg"
  description = "this security group allows ssh , http and https"
  vpc_id = aws_vpc.vpc1.id
  ingress {
    to_port = 22
    from_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "this allows to ssh into ec2 instance"
  }

  ingress {
    to_port = 80
    from_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "this allows http trafic"
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


resource "tls_private_key" "ssh_keys" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "public_key" {
  key_name = "test-key"
  public_key = tls_private_key.ssh_keys.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.ssh_keys.private_key_pem
  filename = "/mnt/c/Users/renupriya/Downloads/test_key.pem"
}

resource "aws_instance" "ec21" {
  ami = var.ami_value
  instance_type = var.instance_type
  key_name = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.public_subnet1.id
  tags = {
    Name = "ec2_instance1"
  }
}

resource "aws_instance" "ec22" {
  ami = var.ami_value
  instance_type = var.instance_type
  key_name = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.public_subnet2.id
  tags = {
    Name = "ec2_instance2"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = tls_private_key.ssh_keys.private_key_pem
    host = self.public_ip
  }
#to copy the file from local to remote host, make sure that file.txt is present in present folder
  provisioner "file" {
    source = "file.txt"
    destination = "/home/ubuntu/file.txt"
  }
 #to ssh into ec2 instance and run the belwo commands
  provisioner "remote-exec" {
    inline = [ 
       "sudo apt update",
       "sudo apt install nginx -y" ,
       "sudo apt install apache -y"
     ]
  }
  #to display it on the console
  provisioner "local-exec" {
    command = "echo the genarated public ip is ${self.public_ip} > public_ip.txt"
  }
}

resource "aws_lb_target_group" "tg" {
  name = "test-target"
  port = 80                   #Your EC2 instances in this group will receive traffic on port 80 (used for websites - HTTP).
  protocol = "HTTP"           #The protocol used to talk to EC2s. Here it is HTTP.
  vpc_id = aws_vpc.vpc1.id
  target_type = "instance"    #This means we are targeting instances directly, not IPs or Lambda.

  health_check {              #used by lb to check the health of instance
    path = "/"                #alb send the request this path , eg http://102.99.9.9/ --if this responds back with 200 it means
                              # the instance is healthy
    protocol = "HTTP"         # this is the protocol used to check the health instance
    interval = 30             #every 30 seconds it checks for health
    timeout = 5               #It waits up to 5 seconds for the EC2 to reply.
    healthy_threshold = 2     #If EC2 replies 2 times in a row → marked as healthy
    unhealthy_threshold = 2   #If EC2 fails to reply 2 times → marked as unhealthy

  }
}

#now attach the instance to target groups
resource "aws_lb_target_group_attachment" "ec1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.ec21.id
  port = 80                     #This tells the Load Balancer to send traffic to the EC2 instance’s port 80. That’s where your web 
                                #server (like Nginx or Apache) is expected to be running.
}

resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.ec22
  port = 80                     #This tells the Load Balancer to send traffic to the EC2 instance’s port 80. That’s where your web 
                                #server (like Nginx or Apache) is expected to be running.
}


resource "aws_lb" "alb" {
  name = "test-alb"
  internal = false    # false = public ALB (accessible from internet)
  load_balancer_type = "application"
  security_groups = [ aws_security_group.sg.id ]
  subnets = [ aws_subnet.public_subnet1.id,aws_subnet.public_subnet2.id ]
  tags = {
    Name = "test-alb"                                  # Just adding a tag to identify the ALB
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn                 #Create a listener for the ALB (like a traffic gate).
  port = 80                                          #Connect this listener to the ALB above.
  protocol = "HTTP"                                  #ALB will listen on port 80 (used for HTTP traffic).
  default_action {                                   #What should ALB do with the traffic?
    target_group_arn = aws_lb_target_group.tg.arn    #Forward it to the target group (where EC2s live).
    type = "forward"
  }
}

#-------------------------------------------------------------------------------------------------------------------------
#---------------------------2.lets see how to use ec2 instance with user data-----------------------------------------------

resource "aws_instance" "ec2" {
  ami = var.ami_value
  instance_type = var.instance_type
  key_name = aws_key_pair.public_key.key_name
  subnet_id = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [ aws_security_group.sg.id ]
  user_data = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo apt install nginx -y
        sudo systemctl start nginx
        EOF
}

resource "aws_instance" "ec2" {
  ami = var.ami_value
  instance_type = var.instance_type
  key_name = aws_key_pair.public_key.key_name
  subnet_id = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [ aws_security_group.sg.id ]
  user_data = file("userdata.sh")
}


#--------------------------------------------------------------------------------------------------------------------------
#-------------------------------3.-LETS NOT DUPLICATE THE RESOURCES NOW------------------------------------------------------
#--------------------------------LETS USE COUNT----------------------------------------------------------------------------

resource "aws_vpc" "vpc1" {
  cidr_block = var.cidr
  tags = {
    Name = "test_vpc"
  }
}

resource "aws_internet_gateway" "ig1"{
  vpc_id = aws_vpc.vpc1.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  count = var.subnet_count
  vpc_id = aws_vpc.vpc1.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = cidrsubnet(var.cidr,8,count.index + 1)  #Terraform’s cidrsubnet() function helps you take a big CIDR block 
                                                     #(like a full VPC range) and cut it into smaller subnets.
                                                     #if VPC is /16, and you add 8 → new subnet will be /24 (because 16+8 = 24)
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig1.id
  }
}

resource "aws_route_table_association" "rt" {
  count = var.subnet_count
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.public_subnets[count.index].id
}

resource "aws_security_group" "sg" {
  name = "test-sg"
  description = "this security group allows ssh , http and https"
  vpc_id = aws_vpc.vpc1.id
  ingress {
    to_port = 22
    from_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "this allows to ssh into ec2 instance"
  }

  ingress {
    to_port = 80
    from_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "this allows http trafic"
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

resource "tls_private_key" "ssh_keys" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "public_key" {
  key_name = "test-key"
  public_key = tls_private_key.ssh_keys.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.ssh_keys.private_key_pem
  filename = "/mnt/c/Users/renupriya/Downloads/test_key.pem"
}

resource "aws_instance" "ec2" {
  count = var.subnet_count
  ami = var.ami_value
  instance_type = var.instance_type
  key_name = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.public_subnets[count.index].id
  tags = {
    Name = "ec2_instance-${count.index +1}"
  }
}

resource "aws_lb_target_group" "tg" {
  name = "test-target"
  port = 80                   #Your EC2 instances in this group will receive traffic on port 80 (used for websites - HTTP).
  protocol = "HTTP"           #The protocol used to talk to EC2s. Here it is HTTP.
  vpc_id = aws_vpc.vpc1.id
  target_type = "instance"    #This means we are targeting instances directly, not IPs or Lambda.

  health_check {              #used by lb to check the health of instance
    path = "/"                #alb send the request this path , eg http://102.99.9.9/ --if this responds back with 200 it means
                              # the instance is healthy
    protocol = "HTTP"         # this is the protocol used to check the health instance
    interval = 30             #every 30 seconds it checks for health
    timeout = 5               #It waits up to 5 seconds for the EC2 to reply.
    healthy_threshold = 2     #If EC2 replies 2 times in a row → marked as healthy
    unhealthy_threshold = 2   #If EC2 fails to reply 2 times → marked as unhealthy

  }
}

#now attach the instance to target groups
resource "aws_lb_target_group_attachment" "ec1_tg" {
  count = var.subnet_count
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.ec2[count.index].id
  port = 80                     #This tells the Load Balancer to send traffic to the EC2 instance’s port 80. That’s where your web                                 #server (like Nginx or Apache) is expected to be running.
}

resource "aws_lb" "alb" {
  name = "test-alb"
  internal = false    # false = public ALB (accessible from internet)
  load_balancer_type = "application"
  security_groups = [ aws_security_group.sg.id ]
  subnets = aws_subnet.public_subnets[*].id
  tags = {
    Name = "test-alb"                                  # Just adding a tag to identify the ALB
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}


#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------4. with count in a different way-------------------------------------------------------------
resource "aws_vpc" "vpc1" {
  cidr_block = var.cidr
  tags = {
    Name = "test_vpc"
  }
}

resource "aws_internet_gateway" "ig1"{
  vpc_id = aws_vpc.vpc1.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  count = length(var.subnet_list)
  vpc_id = aws_vpc.vpc1.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = element(var.subnet_list, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig1.id
  }
}

resource "aws_route_table_association" "rt" {
  count = length(var.subnet_list)
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.public_subnets[count.index].id
}

resource "aws_security_group" "sg" {
  name = "test-sg"
  description = "this security group allows ssh , http and https"
  vpc_id = aws_vpc.vpc1.id
  ingress {
    to_port = 22
    from_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "this allows to ssh into ec2 instance"
  }

  ingress {
    to_port = 80
    from_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "this allows http trafic"
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

resource "tls_private_key" "ssh_keys" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "public_key" {
  key_name = "test-key"
  public_key = tls_private_key.ssh_keys.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.ssh_keys.private_key_pem
  filename = "/mnt/c/Users/renupriya/Downloads/test_key.pem"
}

resource "aws_instance" "ec2" {
  count = length(var.subnet_list)
  ami = var.ami_value
  instance_type = var.instance_type
  key_name = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.public_subnets[count.index].id
  tags = {
    Name = "ec2_instance-${count.index +1}"
  }
}

resource "aws_lb_target_group" "tg" {
  name = "test-target"
  port = 80                   #Your EC2 instances in this group will receive traffic on port 80 (used for websites - HTTP).
  protocol = "HTTP"           #The protocol used to talk to EC2s. Here it is HTTP.
  vpc_id = aws_vpc.vpc1.id
  target_type = "instance"    #This means we are targeting instances directly, not IPs or Lambda.

  health_check {              #used by lb to check the health of instance
    path = "/"                #alb send the request this path , eg http://102.99.9.9/ --if this responds back with 200 it means
                              # the instance is healthy
    protocol = "HTTP"         # this is the protocol used to check the health instance
    interval = 30             #every 30 seconds it checks for health
    timeout = 5               #It waits up to 5 seconds for the EC2 to reply.
    healthy_threshold = 2     #If EC2 replies 2 times in a row → marked as healthy
    unhealthy_threshold = 2   #If EC2 fails to reply 2 times → marked as unhealthy

  }
}

#now attach the instance to target groups
resource "aws_lb_target_group_attachment" "ec1_tg" {
  count = length(var.subnet_list)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.ec2[count.index].id
  port = 80   
  depends_on = [aws_lb.alb]  #not neccsary but safe to add                                   
}

resource "aws_lb" "alb" {
  name = "test-alb"
  internal = false    # false = public ALB (accessible from internet)
  load_balancer_type = "application"
  security_groups = [ aws_security_group.sg.id ]
  subnets = aws_subnet.public_subnets[*].id
  tags = {
    Name = "test-alb"                                  # Just adding a tag to identify the ALB
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}




#------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------
#------------------------------------lets learn about builtin fiucntions--------------------------------------------------------
#concat
variable "test1" {
    default = ["a", "b"]
}

variable "test2" {
    default = ["c", "d"]
}

output "concat" {
  value = concat(var.test1,var.test2)
}

#o/p: concat = ["a", "b", "c", "d"]
#-----------------------------------------------------------------------

#length and element

variable "subnet_list" {
   default = ["10.0.1.0/24", "10.0.2.0.24", "10.0.3.0/24" ]
}

output "length" {
  value = length(var.subnet_list)
}

#o/p: length = 3
#-----------------------------------------------------------------------
output "aws_subnet" {
  value = element(var.subnet_list, count.index)
}

#o/p aws_subnet = "10.0.1.0/24"
#------------------------------------------------------------------------
variable "test4" {
  default = ["a", "b", "cf"]
}

output "join" {
  value = join("|", var.test4)
}

#o/p: join = "a|b|cf"
#------------------------------------------------------------------------
variable "sub1" {
  default = ["apple", "carrot"]
}

variable "sub2" {
  default = ["fruit", "vegetable"]
}

output "zipmap" {
  value = zipmap(var.sub1, var.sub2)
}

#o/p: zipmap = {
#    "apple" = "fruits"
#    "carrot" = "vegetable"
#}
#-------------------------------------------------------------------------
#lookup
variable "instance_type" {
  default = {
    "dev" = "t2.large"
    "staging" = "t2.micro"
    "testing" = "t2.small"
  }
}

resource "aws_instance" "ec2" {
  instance_type = lookup(var.instance_type, terraform.workspace , "t2.micro")
}
#-----------------------------------------------------------------------------
variable "a" {
  type = string
  default = "production"
}

variable "b" {
  type = string
  default = "us-west-1"
}

output "map" {
  value = tomap({
    environment = var.a
    region      = var.b
  })
}

#map = {
# "environment" = "production"
#  "region"      = "us-west-1"
#}

#____________________________________________________________________________________________
#lets learn about locals,variables and tfvars
#--------------------------------------------------------------------------------------------

#________________variable.tf-----------------------------------------------------------------
variable environment{
    type = string
    default = "dev"
}

variable "create_bucket" {
  type = bool
}

variable "region" {
  type = string
}

#____________teraform.tfvats___________________________________________________________________

#environment = "prod"
#create_bucket = true
#region = "us-west-1"

#-------------locals----------------------------------------------------------------------------
locals  {
    bucket_name = "${var.environment}-bucket-Test"
    instance_type = var.environment == "prod" ? "t2.micro" : "t2.large"
    isproductive = var.environment  == "prod" 
}
#--------------------main.tf------------------------------------------------------------------------

resource "aws_bucket" "sb" {
  count = var.create_bucket ? 1 : 0
  bucket = local.bucket_name
}
resource "aws_instance" "test" {
   instance_type = local.instance_type
   count = local.isproductive ? 1 : 0
}



















































































































































































































































































