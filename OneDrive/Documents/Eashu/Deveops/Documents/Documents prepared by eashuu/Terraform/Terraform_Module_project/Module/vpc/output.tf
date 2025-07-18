output "vpc_id" {
  value = aws_vpc.test-vpc.id
}
 output "ig_id" {
   value = aws_internet_gateway.test-ig.id
}
