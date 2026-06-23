# Bootstrap configuration
#
# This is the one piece of infrastructure that is NOT managed through the
# CD pipeline, because it creates the very S3 bucket that all other
# Terraform configurations in this repo use as their remote state backend.
# A backend cannot bootstrap itself - so this directory uses local state,
# is applied once by hand, and is rarely touched again afterwards.
#
# Usage (run once, by a human, before any CI/CD pipeline runs):
#   cd infra/bootstrap
#   terraform init
#   terraform apply -var="project_name=fsl-devops-challenge"

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "project_name" {
  description = "Short project slug, reused as a prefix for the state bucket name."
  type        = string
  default     = "fsl-devops-challenge"
}

variable "aws_region" {
  description = "AWS region the state bucket lives in."
  type        = string
  default     = "us-east-1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"

  # Protect the state bucket from accidental `terraform destroy`.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = var.project_name
    Purpose   = "terraform-remote-state"
    ManagedBy = "terraform-bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  description = "Name of the S3 bucket to reference in each environment's backend.hcl file."
  value       = aws_s3_bucket.terraform_state.id
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC: lets the CI/CD pipeline assume an AWS IAM role using
# short-lived credentials instead of long-lived AWS access keys stored as
# GitHub secrets. This is the current AWS + GitHub recommended pattern.
# ---------------------------------------------------------------------------

variable "github_repository" {
  description = "GitHub repository allowed to assume the deploy role, in 'owner/repo' form."
  type        = string
  default     = "your-github-username/fsl-devops-challenge"
}

# AWS validates the OIDC provider's JWKS endpoint TLS certificate directly
# and does not actually use the configured thumbprint for GitHub's
# provider, but the argument is still required by the resource - fetching
# it dynamically avoids hardcoding a value that could go stale.
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]

  tags = {
    Project = var.project_name
  }
}

# Trust policy: only this repository's `devel` and `stage` branches (and
# their environments, for environment-scoped secrets) may assume the
# role - never a wildcard across all branches or all repositories.
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository}:ref:refs/heads/devel",
        "repo:${var.github_repository}:ref:refs/heads/stage",
        "repo:${var.github_repository}:environment:devel",
        "repo:${var.github_repository}:environment:stage",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.project_name}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Project = var.project_name
  }
}

# Scoped to exactly what the CD pipeline needs: managing the project's own
# S3 buckets, CloudFront distribution, and the Terraform state bucket.
# Deliberately NOT AdministratorAccess.
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid = "TerraformState"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]
  }

  statement {
    sid = "ManageProjectS3Buckets"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-*",
      "arn:aws:s3:::${var.project_name}-*/*",
    ]
  }

  statement {
    sid = "ManageCloudFront"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:UpdateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudfront:TagResource",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ReadCallerAndRegion"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.project_name}-deploy-permissions"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

output "github_actions_role_arn" {
  description = "ARN to set as the AWS_DEPLOY_ROLE_ARN secret in each GitHub environment (devel, stage)."
  value       = aws_iam_role.github_actions_deploy.arn
}
