# Inputs for the ci stack. Defaults fit this project, so no terraform.tfvars is needed.

# TODO: variable "region"  (string, default "us-east-1")
variable "region" {
  type    = string
  default = "us-east-1"
}

# TODO: variable "project" (string, default "eks-gitops-demo")

variable "project" {
  type    = string
  default = "eks-gitops-demo"
}

# TODO: variable "github_repo"   (string, default "dbahr7/eks-gitops-demo")
#   the ONLY repository allowed to assume the role (see oidc.tf)

variable "github_repo" {
  type    = string
  default = "dbahr7/eks-gitops-demo"
}

# TODO: variable "github_branch" (string, default "main")
#   the ONLY branch allowed to assume the role, so a pull request from a fork
#   (or any other branch) can't push images

variable "github_branch" {
  type    = string
  default = "main"
}

# TODO: variable "app_images" (set of strings, default ["api", "web"])
#   one ECR repository per image; ecr.tf loops over this with for_each

variable "app_images" {
  type    = set(string)
  default = ["api", "web"]
}

variable "github_owner_id" {
  type    = string
  default = "37220326"
}

variable "github_repo_id" {
  type    = string
  default = "1461888911"
}
