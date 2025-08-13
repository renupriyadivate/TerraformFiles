variable "cidr_block" {
    description = "this is the cidr block for vpc_id"
}

variable "subnet_count" {
  description = "this give how many the subnets has to be created"
}

variable "instance_type" {
  description = "this is the instance type for the ec2 instance"
}

variable "ami_value" {
  description = "this is the ami value for the ec2 instance creation"
}