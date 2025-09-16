resource "aws_launch_template" "nodejs" {
  name_prefix            = "nodejs-app-"
  image_id               = var.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    cd /home/ec2-user/app
    npm start
  EOF
  )
}

resource "aws_autoscaling_group" "nodejs_asg" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  target_group_arns = [aws_lb_target_group.nodejs_tg.arn]

  launch_template {
    id      = aws_launch_template.nodejs.id
    version = "$Latest"
  }
}

resource "aws_lb" "nodejs_alb" {
  name               = "nodejs-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
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
