
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

# ECS Task Role

Task role allows your container to be granted the various permissions for the required aws services. For this purpose of model deployment, we need access to S3 bucket storing the model versions.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": "arn:aws:s3:::s3-${var.company}-${var.department}-${var.project}-modelstore"
        }
    ]
}
```