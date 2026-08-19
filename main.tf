module "vpc" {
  source       = "./modules/vpc"
  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  public_subnets = {
    public-1 = {
      subnet_cidr = var.public_subnets["public-1"].cidr_block
      subnet_az   = data.aws_availability_zones.available.names[0]
    }
    public-2 = {
      subnet_cidr = var.public_subnets["public-2"].cidr_block
      subnet_az   = data.aws_availability_zones.available.names[1]
    }
  }
  tags = local.common_tags
}


resource "aws_lb" "main" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = values(module.vpc.subnet_ids)
  security_groups    = [aws_security_group.alb_sg.id]
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
  vpc_id   = module.vpc.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
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

resource "aws_launch_template" "web" {
  name_prefix            = "${var.project_name}-web-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.server.id]
  user_data = base64encode(<<-EOF
  #!/bin/bash

  dnf install -y httpd

  TOKEN=$(curl -sS -X PUT \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
    http://169.254.169.254/latest/api/token)

  INSTANCE_ID=$(curl -sS \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id)

  AZ=$(curl -sS \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/placement/availability-zone)

  cat > /var/www/html/index.html <<HTML
  <h1>Independent Terraform Project</h1>
  <p>Instance ID: $INSTANCE_ID</p>
  <p>Availability Zone: $AZ</p>
  HTML

  systemctl enable --now httpd
EOF
  )
}

resource "aws_autoscaling_group" "web" {
  name = "${var.project_name}-web-asg"

  min_size         = 3
  desired_capacity = 3
  max_size         = 6

  vpc_zone_identifier = values(module.vpc.subnet_ids)

  target_group_arns         = [aws_lb_target_group.main.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }

}

resource "aws_security_group" "server" {
  name        = "Server_SG"
  description = "Security group for ec2 instances"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-Server_SG"
  })
}

resource "aws_security_group" "alb_sg" {
  name        = "ALB_SG"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

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