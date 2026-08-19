output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "Output of VPC CIDR block"
}

output "internet_gateway" {
  value       = aws_internet_gateway.gw.id
  description = "ID of the internet gateway"
}

output "subnet_ids" {
  value       = { for k, v in aws_subnet.main : k => v.id }
  description = "IDs of the subnets"
}

output "subnet_cidr_block" {
  value       = { for k, v in aws_subnet.main : k => v.cidr_block }
  description = "Subnet CIDR blocks"
}

output "subnet_availability_zones" {
  value       = { for k, v in aws_subnet.main : k => v.availability_zone }
  description = "Subnet availability zones"
}