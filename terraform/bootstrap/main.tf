# S3 bucket that stores Terraform state for every stack in this project:
#   bootstrap/terraform.tfstate   (this stack, after step 2 in versions.tf)
#   ci/terraform.tfstate          (Phase 3: ECR + GitHub OIDC)
#   platform/terraform.tfstate    (Phase 5: VPC, EKS, DynamoDB)
# Always on. Costs pennies (a few KB of state files).
#
# Every TODO says WHAT is needed. You write the blocks.

# --- 1. Who am I? ------------------------------------------------------------------
# TODO: data source aws_caller_identity
#   gives the account ID, used to make the bucket name globally unique
#   (S3 bucket names are unique across ALL AWS accounts, not just yours)
data "aws_caller_identity" "me" {}

# --- 2. The bucket -------------------------------------------------------------------
# TODO: resource aws_s3_bucket
#   - bucket name: "<project>-tfstate-<account id>"
#       -> eks-gitops-demo-tfstate-396421249317
#   - lifecycle { prevent_destroy = true }
#       Terraform refuses to destroy it, even on `terraform destroy`. Losing this
#       bucket means losing track of everything the other stacks built.
#   Note: since AWS provider v4, versioning/encryption/etc. are NOT arguments of
#   this resource; each is its own resource below, pointing at this bucket's id.

resource "aws_s3_bucket" "state" {
  bucket = "${var.project}-tfstate-${data.aws_caller_identity.me.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

# --- 3. Versioning (required) -----------------------------------------------------------
# TODO: resource aws_s3_bucket_versioning, status "Enabled"
#   Every state write keeps the previous version, so a bad apply or a corrupted
#   state file can be rolled back by restoring an older version.

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- 4. Block all public access (required) --------------------------------------------------
# TODO: resource aws_s3_bucket_public_access_block, all four settings true:
#   block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets
#   State files can contain secrets in plain text. New buckets already default to
#   this, but writing it down makes it visible in review and protects against
#   someone loosening it in the console.

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 5. Encryption at rest -------------------------------------------------------------------
# TODO: resource aws_s3_bucket_server_side_encryption_configuration
#   - a rule with apply_server_side_encryption_by_default, sse_algorithm "AES256" (SSE-S3)
#   S3 already encrypts new objects this way by default, so this documents it.
#   (KMS keys are the stronger option, but cost $1/month each; not needed here.)

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- 6. OPTIONAL: clean up old state versions --------------------------------------------------
# TODO (optional): resource aws_s3_bucket_lifecycle_configuration
#   - one rule, status "Enabled", with an empty filter {} (applies to the whole bucket)
#   - noncurrent_version_expiration: delete OLD versions after 90 days
#   The current state is never touched; this only stops versions piling up forever.

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket     = aws_s3_bucket.state.id
  depends_on = [aws_s3_bucket_versioning.state] # must be versioned to have noncurrent versions
  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {} # empty = whole bucket

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# --- 7. OPTIONAL: refuse non-HTTPS access --------------------------------------------------------
# TODO (optional): resource aws_s3_bucket_policy with a Deny statement for any
#   request where the condition key aws:SecureTransport is "false"
#   (a common audit finding; Terraform itself always uses HTTPS anyway)
resource "aws_s3_bucket_policy" "https_only" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHttps"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}