# A dedicated, private S3 bucket used solely to receive CloudFront
# access logs. Kept separate from the website content bucket so that
# access control, lifecycle rules, and retention policies for logs can
# be managed independently (this is the AWS-recommended pattern).

resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name
  tags   = var.tags
}

# Block all public access; logs must never be directly browsable.
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    # CloudFront standard logging (as opposed to the newer
    # CloudFront-to-S3 "log delivery" / v2 logging) still writes objects
    # using a canned ACL, which requires the bucket to accept ACLs.
    # BucketOwnerPreferred keeps the bucket owner in control of objects
    # while still permitting CloudFront's log delivery ACL.
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }
  }
}
