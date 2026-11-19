# Inputs for the platform stack. Defaults fit this project, so no terraform.tfvars is needed.

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "eks-gitops-demo"
}

variable "kubernetes_version" {
  type    = string
  default = "1.37"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "app_namespace" {
  type    = string
  default = "votes"
}

variable "api_service_account" {
  type    = string
  default = "api"
}
