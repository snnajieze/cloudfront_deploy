# The website content bucket is PRIVATE. Public access happens only
# through CloudFront, which authenticates to S3 using an Origin Access
# Control (OAC) — the current AWS-recommended replacement for the older,
# deprecated Origin Access Identity (OAI). This keeps the origin
# inaccessible if someone discovers the raw S3 URL, satisfying the
# "secure environment" requirement of the challenge while still allowing
# "anyone with Internet access" to reach the app via the CloudFront URL.
#
# NOTE: the bucket policy that actually grants CloudFront read access is
# intentionally NOT defined in this module. It needs the CloudFront
# distribution's ARN as an input, and the distribution needs this
# bucket's regional domain name as an input - so the policy is applied
# one level up, in modules/static_site/main.tf, where both this module's
# and the cloudfront module's outputs are in scope at once.

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}
