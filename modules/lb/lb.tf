
resource "aws_lb" "main" {
  name                       = "lb-${var.company}-${var.project}-${var.env}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = var.security_groups_lb
  subnets                    = var.subnets
  enable_deletion_protection = false
  tags                       = var.tags
}

resource "aws_lb_target_group" "main" {
  # create one TG for each path
  count       = length(var.path_route)
  name        = format("lb-tg-${var.company}-${var.project}-%s-%s", var.path_route[count.index], var.env)
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags        = var.tags

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = format("/%s", var.path_route[count.index])
    unhealthy_threshold = "3"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = element(aws_lb_target_group.main.*.arn, 0)
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "rule" {
  # one rule for each path
  count        = length(var.path_route)
  listener_arn = aws_lb_listener.http.arn
  # priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.*.arn[count.index]
  }
  condition {
    path_pattern {
      values = [format("/%s", var.path_route[count.index])]
    }
  }
}


output "lb_target_group_arns" {
  value = aws_lb_target_group.main.*.arn
}
output "lb_dns" {
  value = aws_lb.main.dns_name
}