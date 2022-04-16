# each ECR will have one eventbridge rule & one lambda function

locals {
  lambda_handler_path = "./modules/eventbridge"
}


resource "aws_cloudwatch_event_rule" "ecr" {
  count = length(var.image_urls)
  name  = format("eventbridge-ecr-push-${var.project}-%s-%s", var.image_names[count.index], var.env)
  tags  = var.tags

  event_pattern = jsonencode({
    source      = ["aws.ecr"],
    detail-type = ["ECR Image Action"],
    detail = {
      action-type     = ["PUSH"],
      result          = ["SUCCESS"],
      repository-name = [split(":", var.image_urls[count.index])[0]],
      image-tag       = [split(":", var.image_urls[count.index])[1]]
    }
  })
}

resource "aws_cloudwatch_event_target" "ecr" {
  count = length(var.image_urls)
  rule  = aws_cloudwatch_event_rule.ecr.*.name[count.index]
  arn   = aws_lambda_function.refresh_ecs_service.*.arn[count.index]
}

resource "aws_lambda_permission" "eventbridge" {
  count         = length(var.image_urls)
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.refresh_ecs_service.*.function_name[count.index]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr.*.arn[count.index]
}

resource "aws_lambda_function" "refresh_ecs_service" {
  count         = length(var.service_nm)
  function_name = format("lambda-ecr-refresh-${var.project}-%s-%s", var.image_names[count.index], var.env)
  filename      = format("%s/%s", local.lambda_handler_path, "refresh_ecs_task.zip")
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "refresh_ecs_task.lambda_handler"
  runtime       = "python3.8"
  tags          = var.tags

  environment {
    variables = {
      CLUSTER_NM = var.cluster_nm
      SERVICE_NM = var.service_nm[count.index]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam-lambda-${var.project}-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "zipit" {
  type        = "zip"
  source_file = format("%s/%s", local.lambda_handler_path, "refresh_ecs_task.py")
  output_path = format("%s/%s", local.lambda_handler_path, "refresh_ecs_task.zip")
}