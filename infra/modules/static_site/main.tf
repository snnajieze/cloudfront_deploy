locals {
  bucket_name         = "${var.project_name}-${var.environment}-site-${data.aws_caller_identity.current.account_id}"
  logging_bucket_name = "${var.project_name}-${var.environment}-logs-${data.aws_caller_identity.current.account_id}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

data "aws_caller_identity" "current" {}

# 1. Logging bucket. Nothing else depends on this existing first, but it's
# referenced by the CloudFront module below, so create it up front.
module "logging_bucket" {
  source = "../../modules/logging_bucket"

  bucket_name        = local.logging_bucket_name
  log_retention_days = var.log_retention_days
  tags               = local.common_tags
}

# 2. Website content bucket - created before CloudFront, with no public
# access and no policy yet (the policy needs the distribution's ARN,
# which doesn't exist until step 3).
module "website_bucket" {
  source = "../../modules/s3_website"

  bucket_name = local.bucket_name
  tags        = local.common_tags
}

# 3. CloudFront distribution. Its origin domain_name references the real
# bucket resource output (module.website_bucket.bucket_regional_domain_name),
# not a synthetic/hand-built string, so Terraform's dependency graph
# guarantees the bucket exists before CloudFront tries to validate it as
# an origin.
module "cdn" {
  source = "../../modules/cloudfront"

  comment                            = "${var.project_name} (${var.environment})"
  origin_bucket_id                   = module.website_bucket.bucket_id
  origin_bucket_regional_domain_name = module.website_bucket.bucket_regional_domain_name
  logging_bucket_domain_name         = module.logging_bucket.bucket_domain_name
  enabled                            = var.enabled
  price_class                        = var.price_class
  tags                               = local.common_tags
}

# 4. Bucket policy, applied here (rather than inside the s3_website
# module) because it needs module.cdn.distribution_arn, which only
# exists after CloudFront is created. Granting access is scoped to this
# one distribution via the AWS:SourceArn condition - no public or
# account-wide access is ever granted.
data "aws_iam_policy_document" "website_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${module.website_bucket.bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = module.website_bucket.bucket_id
  policy = data.aws_iam_policy_document.website_bucket_policy.json
}
