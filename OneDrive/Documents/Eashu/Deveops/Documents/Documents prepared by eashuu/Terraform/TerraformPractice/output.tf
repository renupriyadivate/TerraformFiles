output "load_dns_name" {
  value = aws_lb.alb.dns_name
}

output "public_keys" {
  value = {
    for i in aws_instance.ec2 : i.tags["Name"] => i.public_ip
  }
}