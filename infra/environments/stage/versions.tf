terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Partial backend configuration - bucket/key/region are supplied at
  # `terraform init -backend-config=backend.hcl` time (or via the CD
  # pipeline passing the same file) so this file never has to be edited
  # to point at different AWS accounts.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "stage"
      ManagedBy   = "terraform"
    }
  }
}
