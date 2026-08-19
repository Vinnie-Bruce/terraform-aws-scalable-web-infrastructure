output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_id" {
  value = module.vpc.subnet_ids
}

output "public_subnet_cidr_block" {
  value = module.vpc.subnet_cidr_block
}

output "public_subnet_availability_zone" {
  value = module.vpc.subnet_availability_zones
}

output "application_load_balancer_dns_name" {
  value = aws_lb.main.dns_name
}