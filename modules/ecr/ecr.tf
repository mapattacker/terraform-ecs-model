
resource "aws_ecr_repository" "modelimage" {
  count                = length(var.models)
  name                 = format("ecr-${var.company}-${var.department}-${var.project}-%s", var.models[count.index])
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  count      = length(var.models)
  repository = aws_ecr_repository.modelimage.*.name[count.index]

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

output "ecr_image_url" {
  value = aws_ecr_repository.modelimage.*.repository_url
}