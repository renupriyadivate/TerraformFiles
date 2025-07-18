variable "cidr" {
  description = "the cidr value for vpc"
}

variable "subnet_cidr" {
  description = "the cidr for both public and private subnets"
  type = list(string)
}

variable "ami_value" {
  description = "the ami value for ec2 instance"
}

variable "instance_type" {}


#-----------------------------------------------------------------------------------------------------------------
#---------------------------------------3.setting variables for 3 part in main.tf---------------------------------
#-----------------------------------------------------------------------------------------------------------------

variable "subnet_count" {
  type = number
}


#-----------------------------------------------------------------------------------------------------------------
#---------------------------------------4.setting variables for 4 part in main.tf---------------------------------
#-----------------------------------------------------------------------------------------------------------------


variable "subnet_list" {
  type = list(string)
}
