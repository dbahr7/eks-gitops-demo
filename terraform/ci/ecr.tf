# ECR repositories for the two images. Always on, so GitHub Actions can push
# whether or not the EKS cluster exists.

resource "aws_ecr_repository" "app" {
  for_each = var.app_images

  name = "${var.project}/${each.key}"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = var.app_images

  repository = aws_ecr_repository.app[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
