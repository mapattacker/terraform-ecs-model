
# ECS Task Execution Role

To allow the ECS task to create a Cloudwatch log group for each container definition, the original permissions of **AmazonECSTaskExecutionRolePolicy** is not enough. You have to create a new policy with *logs:CreateLogGroup* in it.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        }
    ]
}
```