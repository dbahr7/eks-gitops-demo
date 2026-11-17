# Values the other stacks need for their `backend "s3"` blocks.

# TODO: output "state_bucket"  -> the bucket's name (its id)

output "state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.state.id
}

# TODO: output "region"        -> the region variable
output "region" {
  description = "Region for the S3 bucket"
  value       = var.region
}