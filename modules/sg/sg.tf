
resource "aws_security_group" "lb" {
  name   = "tf-sg-alb-${var.project}-${var.env}"
  vpc_id = var.vpc_id
  tags   = var.tags

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ecs_service" {
  name   = "tf-sg-ecs-service-${var.project}-${var.env}"
  vpc_id = var.vpc_id
  tags   = var.tags

  dynamic "ingress" {
    # create multiple ingress
    for_each = var.container_ports

    content {
      protocol         = "tcp"
      from_port        = ingress.value
      to_port          = ingress.value
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


output "security_group_lb" {
  value = aws_security_group.lb.id
}
output "security_group_ecs_service" {
  value = aws_security_group.ecs_service.id
}