# Values the GitHub Actions workflow (Phase 4) and the platform stack (Phase 5) need.

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_repository_urls" {
  description = "Map of image name -> ECR repository URL"
  value       = { for k, r in aws_ecr_repository.app : k => r.repository_url }
}
