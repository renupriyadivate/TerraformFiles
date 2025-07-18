output "subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "subnet_count" {
  value = length(var.subnet_cidr)
}


