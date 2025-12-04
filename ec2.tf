resource "aws_launch_template" "nodejs" {
  name_prefix            = "nodejs-app-"
  image_id               = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  depends_on             = [aws_secretsmanager_secret_version.db_secret_value]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    cd /home/ec2-user/app
    node index.js
  EOF
  )

  iam_instance_profile {
    name = "LabInstanceProfile"
  }
}

resource "aws_autoscaling_group" "nodejs_asg" {
  min_size                = 1
  max_size                = 4
  vpc_zone_identifier     = [for s in values(aws_subnet.private) : s.id]
  target_group_arns       = [aws_lb_target_group.nodejs_tg.arn]
  depends_on              = [aws_secretsmanager_secret_version.db_secret_value]
  default_cooldown        = 60
  default_instance_warmup = 60

  launch_template {
    id      = aws_launch_template.nodejs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "nodejs-app"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_policy" {
  name                      = "cpu-target-policy"
  autoscaling_group_name    = aws_autoscaling_group.nodejs_asg.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 30.0
  }
}

resource "aws_lb" "nodejs_alb" {
  name               = "nodejs-alb"
  load_balancer_type = "application"
  subnets            = [for s in values(aws_subnet.public) : s.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "nodejs_tg" {
  name     = "nodejs-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = "3000"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nodejs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nodejs_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.nodejs_alb.dns_name
}
