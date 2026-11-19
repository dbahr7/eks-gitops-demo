# Inputs for the ci stack. Defaults fit this project, so no terraform.tfvars is needed.

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "eks-gitops-demo"
}

variable "github_repo" {
  type    = string
  default = "dbahr7/eks-gitops-demo"
}

variable "github_branch" {
  type    = string
  default = "main"
}

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
