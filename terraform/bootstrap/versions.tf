# Terraform and provider versions, plus the provider configuration.

terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Stack     = "bootstrap"
      ManagedBy = "terraform"
    }
  }
}



# --- Step 2, AFTER the first apply (leave it out for now) ----------------------------
# Chicken-and-egg: this stack CREATES the state bucket, so its own first state has to
# be local. Once the bucket exists, add a backend block inside `terraform { }`:
#   backend "s3" with bucket = <the new bucket>, key = "bootstrap/terraform.tfstate",
#   region, and use_lockfile = true
# then run `terraform init -migrate-state` to move the local state into the bucket.
# Why bother: a git-ignored local state file is what got lost in the Mac -> Windows
# move (the orphaned Career Compass VPC). In S3 with versioning, it can't be lost that way.


