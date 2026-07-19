# ─── Latest Ubuntu 22.04 AMI ───────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── IAM Role for SSM (keyless secure access) ──────────────────
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-${var.environment}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-${var.environment}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# ─── Security Group: ALB (public-facing, port 80) ───────────────
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow inbound HTTP from the internet to the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# ─── Security Group: EC2 instances (only reachable from ALB) ────
resource "aws_security_group" "instance_sg" {
  name        = "${var.project_name}-${var.environment}-instance-sg"
  description = "Allow app traffic only from the ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-sg"
  }
}

# ─── Application Load Balancer ───────────────────────────────────
resource "aws_lb" "app" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ─── Launch Template ──────────────────────────────────────────────
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-app-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── Auto Scaling Group ────────────────────────────────────────────
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier = var.asg_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}

# ─── Auto Scaling Policy: scale on average CPU ─────────────────────
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-${var.environment}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
