# Values the GitHub Actions workflow (Phase 4) and the platform stack (Phase 5) need.

# TODO: output "github_actions_role_arn"
#   the role's ARN; the workflow passes it to aws-actions/configure-aws-credentials.
#   Not a secret (an ARN alone grants nothing), so it can go in a GitHub repo variable.

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role"
  value       = aws_iam_role.github_actions.arn
}

# TODO: output "ecr_repository_urls"
#   a map of image name -> repository URL, e.g.
#   { api = "396421249317.dkr.ecr.us-east-1.amazonaws.com/eks-gitops-demo/api", web = ... }
#   hint: { for k, r in aws_ecr_repository.app : k => r.repository_url }

output "ecr_repository_urls" {
  description = "Map of image name -> ECR repository URL"
  value       = { for k, r in aws_ecr_repository.app : k => r.repository_url }
}
