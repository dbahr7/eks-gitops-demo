# Lets GitHub Actions push images to ECR WITHOUT any AWS keys stored in GitHub.
#
# How it works, per workflow run:
#   1. GitHub gives the job a short-lived signed token (a JWT) that says
#      who it is, e.g. sub = "repo:dbahr7/eks-gitops-demo:ref:refs/heads/main".
#   2. The job sends that token to AWS STS: AssumeRoleWithWebIdentity.
#   3. STS checks the signature against the OIDC provider below, then checks the
#      role's TRUST POLICY conditions against the token's claims.
#   4. If both pass, STS returns temporary credentials (1 hour) for the role.
#      Nothing long-lived exists to leak.
#
# Every TODO says WHAT is needed. You write the blocks. The trust policy (part 3)
# is the security-critical part: we'll go through it line by line in review.

# --- 1. The OIDC provider: "AWS, trust tokens signed by GitHub Actions" ---------------
# TODO: resource aws_iam_openid_connect_provider
#   - url            = "https://token.actions.githubusercontent.com"
#   - client_id_list = ["sts.amazonaws.com"]   (the "audience" GitHub's token is issued for)
#   - thumbprint_list: leave it out. AWS now verifies GitHub's certificate itself,
#     and the AWS provider made this argument optional.
#   One per account per URL. None exists in this account yet (checked 2026-11-17).

locals {
  github_owner = split("/", var.github_repo)[0] # "dbahr7"
  github_name  = split("/", var.github_repo)[1] # "eks-gitops-demo"
  github_sub   = "repo:${local.github_owner}@${var.github_owner_id}/${local.github_name}@${var.github_repo_id}:ref:refs/heads/${var.github_branch}"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# --- 2. The role -------------------------------------------------------------------------
# TODO: resource aws_iam_role
#   - name: "<project>-github-actions"
#   - assume_role_policy: the trust policy from part 3

resource "aws_iam_role" "github_actions" {
  name = "${var.project}-github-actions"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# --- 3. The trust policy: WHO may assume the role ------------------------------------------
# Write it with jsonencode (as in bootstrap) or with a data "aws_iam_policy_document"
# block (Terraform's native way; easier to read for conditions). Either is fine.
# TODO: one statement:
#   - Effect    = "Allow"
#   - Principal = Federated: the OIDC provider's ARN from part 1
#   - Action    = "sts:AssumeRoleWithWebIdentity"
#   - Condition, operator StringEquals, BOTH of these:
#       "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#           the token was issued for AWS STS, not for some other service
#       "token.actions.githubusercontent.com:sub" = "repo:<github_repo>:ref:refs/heads/<github_branch>"
#           -> repo:dbahr7/eks-gitops-demo:ref:refs/heads/main
#           THE critical line. Every public repo on GitHub can get a token from this
#           same provider; without a sub condition, any of them could assume your role.
#           StringEquals (exact match), not StringLike with "*" wildcards.

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_sub]
    }
  }
}

# --- 4. The permissions: WHAT the role may do once assumed ------------------------------------
# TODO: resource aws_iam_role_policy (inline policy, attached to the role from part 2)
#   Statement A: log in to ECR
#     - Action   = "ecr:GetAuthorizationToken"
#     - Resource = "*"   (this one action can't be limited to a repository: AWS
#                         requires "*" for it. It only issues a login token.)
#   Statement B: push to OUR TWO repositories only
#     - Actions: ecr:BatchCheckLayerAvailability, ecr:InitiateLayerUpload,
#                ecr:UploadLayerPart, ecr:CompleteLayerUpload, ecr:PutImage,
#                ecr:BatchGetImage
#     - Resource = the ARNs of both repositories
#         hint: [for r in aws_ecr_repository.app : r.arn]
#   No delete, no other services, no other repositories.

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project}-github-actions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Sid      = "ECRLogin"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Sid    = "PushToAppRepos"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ]
        Resource = [for r in aws_ecr_repository.app : r.arn]
      }
    ]
  })
}
