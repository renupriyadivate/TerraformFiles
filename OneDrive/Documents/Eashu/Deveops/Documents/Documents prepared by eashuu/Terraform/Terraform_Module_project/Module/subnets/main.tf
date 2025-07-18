resource "aws_subnet" "public_subnets" {
  count = length(var.subnet_cidr)
  vpc_id = var.vpc_id
  availability_zone = element(var.availability_zone, count.index)
  cidr_block = element(var.subnet_cidr, count.index)
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}