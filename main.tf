resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-VPC"
  })
}


resource "aws_subnet" "main" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[index(keys(var.public_subnets), each.key)]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-subnet"
  })
}


data "aws_availability_zones" "available" {
  state = "available"
}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}


resource "aws_instance" "web" {
  for_each      = aws_subnet.main
  subnet_id     = each.value.id
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-instance"
  })
}