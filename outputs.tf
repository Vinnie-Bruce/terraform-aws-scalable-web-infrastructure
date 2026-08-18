output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  value = { for k, v in aws_subnet.main : k => v.id }
}

output "public_subnet_cidr_block" {
  value = { for k, v in aws_subnet.main : k => v.cidr_block }
}

output "public_subnet_availability_zone" {
  value = { for k, v in aws_subnet.main : k => v.availability_zone }
}

output "application_load_balancer_dns_name" {
  value = aws_lb.main.dns_name
}