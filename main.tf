resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-VPC"
  })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-GW"
  })
}

resource "aws_lb" "main" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    for subnet in aws_subnet.main : subnet.id
  ]
  security_groups = [aws_security_group.alb_sg.id]
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ALB"
  })
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group" "main" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  for_each = {
    for instance_name, instance in aws_instance.web : instance_name => instance
  }
  target_id = each.value.id
  port      = 80
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
  for_each                    = aws_subnet.main
  subnet_id                   = each.value.id
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.server.id]
  user_data                   = <<-EOF
  #!/bin/bash
  dnf install -y httpd
  echo "<h1>Terraform ALB Node: ${each.key}</h1>" > /var/www/html/index.html
  systemctl enable httpd
  systemctl start httpd
EOF

  user_data_replace_on_change = true
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-instance"
  })
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public_RT"
  })
}

resource "aws_route_table_association" "main" {
  for_each       = aws_subnet.main
  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "server" {
  name        = "Server_SG"
  description = "Security group for ec2 instances"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Server_SG"
  })
}

resource "aws_security_group" "alb_sg" {
  name        = "ALB_SG"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ALB_SG"
  })
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all traffic outbound"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id            = aws_security_group.server.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Ingress rule to allow tcp traffic over port 80"
}

resource "aws_vpc_security_group_ingress_rule" "allow_traffic" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "Ingress rule to allow tcp traffic over port 80"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allowing all traffic out"
}