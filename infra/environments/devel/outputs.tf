output "bucket_id" {
  description = "S3 bucket name the CD pipeline syncs the built app into."
  value       = module.site.bucket_id
}

output "distribution_id" {
  description = "CloudFront distribution ID, used by the CD pipeline to invalidate the cache after each deploy."
  value       = module.site.distribution_id
}

output "site_url" {
  description = "Public HTTPS URL of the deployed devel environment."
  value       = module.site.site_url
}
