resource "aws_route_table" "public_rts" {
  vpc_id = var.vpc_id
  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route" "default" {
  route_table_id = aws_route_table.public_rts.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = var.gateway_id
}

resource "aws_route_table_association" "rts" {
  count = length(var.subnet_ids)
  route_table_id = aws_route_table.public_rts.id
  subnet_id = element(var.subnet_ids, count.index)
}

