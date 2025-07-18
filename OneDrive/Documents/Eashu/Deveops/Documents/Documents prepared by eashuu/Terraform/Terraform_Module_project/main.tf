module "vpc" {
  source = "./Module/vpc"
  cidr = var.cidr
  vpc_name = var.vpc_name
  ig-name = var.ig-name
}

data "aws_availability_zones" "available" {}

module "subnets" {

  source = "./Module/subnets"
  subnet_cidr = var.subnet_cidr
  vpc_id = module.vpc.vpc_id
  availability_zone = data.aws_availability_zones.available.names
  
}

module "route_table" {
  source = "./Module/route_table"
  vpc_id = module.vpc.vpc_id
  gateway_id = module.vpc.ig_id
  subnet_ids = module.subnets.subnet_ids
  route_table_name = var.route_table_name
}


module "sg" {
  source = "./Module/security_group"
  vpc_id = module.vpc.vpc_id
  security_name = var.security_name
}

module "key" {
  source = "./Module/key_pair"
  key_name = var.key_name
  filename = var.filename
}

module "ec2" {
  source = "./Module/ec2"
  ami = var.ami
  instance_type = var.instance_type
  key_name = module.key.key_name
  subnet_ids = module.subnets.subnet_ids
  security_group_id = module.sg.security_group_id
}