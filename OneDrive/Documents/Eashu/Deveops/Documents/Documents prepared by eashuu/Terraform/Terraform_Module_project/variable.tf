variable "cidr" {
  type = string
}
variable "vpc_name" {
  type = string
}

variable "ig-name" {
  type = string
}

variable "subnet_cidr" {
  type = list(string)
}

variable "availability_zone" {
  type = list(string)
}

variable "route_table_name" {
   type = string
}

variable "subnet_cidr" {
   type = list(string)
}

variable "security_name" {
  type = string
}

variable "key_name" {
  type = string
}

variable "filename" {
  type = string
}
variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}








