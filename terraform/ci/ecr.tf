# ECR repositories for the two images. Always on, so GitHub Actions can push
# whether or not the EKS cluster exists.
#
# New concept: for_each. ONE resource block creates one repository per item in
# var.app_images. Inside the block, each.key is the current item ("api" or "web").
# The results are addressed as aws_ecr_repository.app["api"] / ["web"].
#
# Every TODO says WHAT is needed. You write the blocks.

# --- 1. The repositories -----------------------------------------------------------
# TODO: resource aws_ecr_repository, with for_each = var.app_images
#   - name: "<project>/<image>"  -> eks-gitops-demo/api, eks-gitops-demo/web
#       (the "/" is just part of the name; it groups them in the console and keeps
#        them apart from k8s-lab's votes-api / votes-web)
#   - image_scanning_configuration block with scan_on_push = true
#       free basic scan for known CVEs on every push (agreed add-on)
#   - image_tag_mutability = "IMMUTABLE"   (recommended, my addition)
#       a tag can never be pushed twice. With git-SHA tags that's exactly right:
#       the tag a pod runs always means the same image. It's the k8s-lab problem
#       of re-pushing "0.1" and nodes keeping the old one, made impossible.
#   - leave force_delete off (default false): Terraform won't delete a repository
#     that still has images in it

resource "aws_ecr_repository" "app" {
  for_each = var.app_images

  name = "${var.project}/${each.key}"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"
}

# --- 2. Lifecycle policy: keep the last 10 images ---------------------------------------
# TODO: resource aws_ecr_lifecycle_policy, ALSO with for_each = var.app_images
#   - repository: the matching repository's name (aws_ecr_repository.app[each.key].name)
#   - policy: jsonencode of an object with a "rules" list holding one rule:
#       rulePriority = 1
#       description  = "keep last 10 images"
#       selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }
#       action       = { type = "expire" }
#   ECR storage is $0.10/GB-month; this keeps it at pennies while leaving
#   plenty of recent versions to roll back to.

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
