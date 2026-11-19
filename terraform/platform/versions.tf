# Versions, remote state and provider for the platform stack (DESTROYABLE: costs money while up).

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
    key          = "platform/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Stack     = "platform"
      ManagedBy = "terraform"
    }
  }
}
