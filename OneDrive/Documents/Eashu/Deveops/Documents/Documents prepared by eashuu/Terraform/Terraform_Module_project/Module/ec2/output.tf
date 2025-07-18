output "instance_ids" {
  value = aws_instance.ec2[*].id
}

output "public-ips" {
  value = aws_instance.ec2[*].public_key
}
