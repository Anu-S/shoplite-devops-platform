# This file provisions the S3 bucket + DynamoDB table that Terraform itself
# will use to store its state file remotely, instead of on your laptop.
#
# WHY THIS MATTERS (interview-relevant):
# - By default, Terraform state lives in a local terraform.tfstate file.
#   That's fine solo, but breaks the moment more than one person (or one
#   CI pipeline + one person) touches the same infrastructure — you lose
#   track of what's real.
# - Storing state in S3 means everyone/everything reads and writes the
#   SAME state file.
# - The DynamoDB table adds locking: if Terraform is already applying
#   changes, a second `terraform apply` will wait/fail instead of
#   corrupting the state by writing at the same time.
#
# NOTE: this file is applied ONCE, manually, BEFORE anything else — you
# can't store state in a bucket that doesn't exist yet (chicken-and-egg).
# After this exists, main.tf's backend block points at it.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "terraform_state" {
  # Bucket names must be globally unique across ALL of AWS, not just your
  # account — so this includes your account ID to guarantee uniqueness.
  bucket = "shoplite-terraform-state-${data.aws_caller_identity.current.account_id}"

  # Prevents accidentally deleting this bucket (and your state!) with
  # `terraform destroy` run against the wrong directory.
  lifecycle {
    prevent_destroy = true
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled" # keeps history of every state change — recoverable if corrupted
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "shoplite-terraform-locks"
  billing_mode = "PAY_PER_REQUEST" # free-tier friendly — no idle cost
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
