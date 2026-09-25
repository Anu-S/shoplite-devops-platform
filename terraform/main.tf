# Root module — this is what you actually run `terraform apply` against.
# It wires the VPC module together and points Terraform at the remote
# state backend created by terraform/bootstrap/main.tf.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # IMPORTANT: fill in YOUR bucket name (from the bootstrap output) below
  # before running `terraform init`. Terraform does not allow variables
  # inside a backend block, so this has to be a literal value.
  backend "s3" {
    bucket         = "shoplite-terraform-state-959579700484"
    key            = "shoplite/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "shoplite-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project   = "shoplite-devops-platform"
      ManagedBy = "terraform"
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name       = "shoplite"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-south-1a", "ap-south-1b"]
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
