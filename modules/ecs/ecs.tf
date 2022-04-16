
resource "aws_ecs_cluster" "main" {
  # ECS cluster
  name = "ecs-cluster-${var.project}-${var.env}"
  tags = var.tags
}

resource "aws_ecs_task_definition" "main" {
  # ECS task definition
  count                    = length(var.image_names)
  family                   = format("ecs-task-def-%s", element(var.image_names, count.index))
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tonumber(element(var.cpu, count.index))
  memory                   = tonumber(element(var.memory, count.index))
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  tags                     = var.tags

  container_definitions = jsonencode([{
    name      = format("container-${var.project}-%s", element(var.image_names, count.index))
    image     = element(var.image_urls, count.index)
    essential = true
    portMappings = [{
      protocol      = "tcp"
      containerPort = tonumber(element(var.container_ports, count.index))
      hostPort      = tonumber(element(var.container_ports, count.index))
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = format("/ecs/${var.project}/%s", element(var.image_names, count.index))
        awslogs-create-group  = "true"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}


resource "aws_ecs_service" "main" {
  # one service for each model
  count                              = length(var.image_names)
  name                               = format("ecs-service-${var.project}-%s-%s", element(var.image_names, count.index), var.env)
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = element(aws_ecs_task_definition.main.*.arn, count.index)
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = var.security_groups_ecs
    subnets          = var.subnets_public
    assign_public_ip = var.public_ip
  }

  load_balancer {
    target_group_arn = element(var.lb_tg_arns, count.index)
    container_name   = format("container-${var.project}-%s", element(var.image_names, count.index))
    container_port   = element(var.container_ports, count.index)
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}




resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs-taskrole-${var.project}-${var.env}"
  tags               = var.tags
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "s3" {
  name        = "ecs-task-policy-${var.project}-${var.env}"
  description = "Policy that allows read access to S3 for model download"
  tags        = var.tags
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:Get*",
          "s3:List*"
        ],
        Resource = "arn:aws:s3:::${var.s3_model_bucket}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3.arn
}


resource "aws_iam_role" "ecs_task_execution_role" {
  # for ECS to pull ECR, and add logs
  name               = "ecs-TaskExecutionRole-${var.project}-${var.env}"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::753251591776:policy/ECSTaskExecutionRolePolicywithCreatelogGroup"
}


# ------------
# Auto Scaling

resource "aws_appautoscaling_target" "ecs_target" {
  count              = length(aws_ecs_service.main.*.name)
  max_capacity       = 1
  min_capacity       = 1
  resource_id        = format("service/%s/%s", "${aws_ecs_cluster.main.name}", "${element(aws_ecs_service.main.*.name, count.index)}")
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "shutdown" {
  count              = length(aws_ecs_service.main.*.name)
  name               = "shutdown"
  service_namespace  = element(aws_appautoscaling_target.ecs_target.*.service_namespace, count.index)
  resource_id        = element(aws_appautoscaling_target.ecs_target.*.resource_id, count.index)
  scalable_dimension = element(aws_appautoscaling_target.ecs_target.*.scalable_dimension, count.index)
  schedule           = var.shutdown

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

resource "aws_appautoscaling_scheduled_action" "turnon" {
  count              = length(aws_ecs_service.main.*.name)
  name               = "turnon"
  service_namespace  = element(aws_appautoscaling_target.ecs_target.*.service_namespace, count.index)
  resource_id        = element(aws_appautoscaling_target.ecs_target.*.resource_id, count.index)
  scalable_dimension = element(aws_appautoscaling_target.ecs_target.*.scalable_dimension, count.index)
  schedule           = var.turnon

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}


output "cluster_nm" {
  value = aws_ecs_cluster.main.name
}
output "service_nm" {
  value = aws_ecs_service.main.*.name
}