variable "vpc_id" {
  type = string
}

variable "route_table_name" {
   type = string
}

variable "gateway_id" {
   type = string
}

variable "subnet_ids" {
   type = list(string)
}



