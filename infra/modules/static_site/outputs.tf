output "bucket_id" {
  description = "Name of the S3 bucket that holds the built application. The CD pipeline syncs build output here."
  value       = module.website_bucket.bucket_id
}

output "logging_bucket_id" {
  description = "Name of the S3 bucket that stores CloudFront access logs."
  value       = module.logging_bucket.bucket_id
}

output "distribution_id" {
  description = "CloudFront distribution ID. Needed by the CD pipeline to create cache invalidations after each deploy."
  value       = module.cdn.distribution_id
}

output "distribution_domain_name" {
  description = "CloudFront domain name. This is the public URL where the application is reachable."
  value       = module.cdn.distribution_domain_name
}

output "site_url" {
  description = "Convenience HTTPS URL for the deployed application."
  value       = "https://${module.cdn.distribution_domain_name}"
}
