resource "aws_instance" "ec2" {
  count = length(var.subnet_ids)
  ami = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  subnet_id = element(var.subnet_ids, count.index)
  security_groups = var.security_group_id

  tags = {
    Name = "public-instance-${count.index + 1}"
  }
}