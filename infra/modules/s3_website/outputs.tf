output "bucket_id" {
  description = "ID (name) of the website content bucket."
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "ARN of the website content bucket."
  value       = aws_s3_bucket.website.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket, used as the CloudFront origin domain_name."
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}
