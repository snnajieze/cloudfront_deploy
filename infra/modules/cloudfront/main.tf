# Origin Access Control: the current (non-deprecated) mechanism CloudFront
# uses to sign requests to a private S3 origin. Replaces the legacy
# Origin Access Identity (OAI).
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.origin_bucket_id}-oac"
  description                       = "OAC for ${var.origin_bucket_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  is_ipv6_enabled     = true
  comment             = var.comment
  default_root_object = var.default_root_object
  price_class         = var.price_class

  origin {
    domain_name              = var.origin_bucket_regional_domain_name
    origin_id                = var.origin_bucket_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.origin_bucket_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Managed cache/origin-request policies (no need to declare a custom
    # cache_policy resource for a simple static-site use case):
    #   CachingOptimized: 658327ea-f89d-4fab-a63d-7e88639e58f6
    #   CORS-S3Origin:    88a5eaf4-2f7a-4f8b-9c46-8c48c0a17bf1
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id = "88a5eaf4-2f7a-4f8b-9c46-8c48c0a17bf1"
  }

  # The sample app is a client-side-routed single page app. Any path not
  # found as a literal S3 object (403 from the bucket policy when listing
  # is denied, or 404 if truly missing) should fall back to index.html so
  # client-side routing can take over.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  logging_config {
    bucket          = var.logging_bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = var.tags
}
