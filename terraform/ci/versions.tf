# Terraform/provider versions, remote state, and provider config for the ci stack.


terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }

  backend "s3" {
    bucket       = "eks-gitops-demo-tfstate-396421249317"
    key          = "ci/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

# TODO: provider "aws" block, same as bootstrap's, but with Stack = "ci" in default_tags

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Stack     = "ci"
      ManagedBy = "terraform"
    }
  }
}
