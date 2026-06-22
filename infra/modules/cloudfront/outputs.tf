output "distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution. Used to scope the S3 bucket policy to this specific distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "CloudFront-assigned domain name (e.g. d111111abcdef8.cloudfront.net) where the application is publicly reachable."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront's Route 53 hosted zone ID, useful if an alias record is added later."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
