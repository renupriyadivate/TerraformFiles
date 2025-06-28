resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_id
}

resource "aws_internet_gateway" "ig1" {
  vpc_id = aws_vpc.vpc1.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig1.id
  }
}

resource "aws_route_table_association" "ass" {
  subnet_id = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc1.id
  description = "allow ssh , http and https"
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
resource "aws_instance" "ec2" {
  instance_type = var.instance_type
  ami = var.ami
  subnet_id = aws_subnet.sub1.id
  vpc_security_group_ids = [ aws_security_group.sg.id ]
}