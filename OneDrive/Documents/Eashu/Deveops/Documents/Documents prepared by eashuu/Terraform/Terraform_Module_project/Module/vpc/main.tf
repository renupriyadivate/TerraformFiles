resource "aws_vpc" "test-vpc" {
  cidr_block = var.cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "test-ig" {
  vpc_id = aws_vpc.test-vpc.id
  tags =  {
    Name = var.ig-name
  }
}