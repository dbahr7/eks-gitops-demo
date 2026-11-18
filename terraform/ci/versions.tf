# Terraform/provider versions, remote state, and provider config for the ci stack.
# Every TODO says WHAT is needed. You write the blocks.

# TODO: a `terraform { ... }` block, same as bootstrap's, PLUS the backend from day one:
#   - required_version ">= 1.11"
#   - required_providers: aws, source "hashicorp/aws", version "~> 6.73"
#   - backend "s3":
#       bucket       = the state bucket from Phase 2 (written out in full: no variables here)
#       key          = "ci/terraform.tfstate"   <- each stack gets its own key (file) in the bucket
#       region       = "us-east-1"
#       use_lockfile = true
#   No migration this time: the bucket already exists, so `terraform init` starts
#   with remote state straight away.

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
