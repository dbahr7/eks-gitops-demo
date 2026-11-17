# Inputs for the bootstrap stack. Defaults are fine for this project, so no
# terraform.tfvars is needed.

# TODO: variable "region"  (string, default "us-east-1")

variable "region" {
  type    = string
  default = "us-east-1"
}

# TODO: variable "project" (string, default "eks-gitops-demo")
#   used as the prefix for the bucket name and in tags, so nothing collides
#   with k8s-lab's resources in the same account

variable "project" {
  type    = string
  default = "eks-gitops-demo"
}
