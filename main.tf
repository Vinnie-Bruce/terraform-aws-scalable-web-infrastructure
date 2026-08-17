resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "Main VPC"
  }
}

resource "aws_subnet" "main" {
  for_each = var.public_subnets
  vpc_id   = aws_vpc.main.id

}