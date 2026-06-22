variable "comment" {
  description = "Comment describing this CloudFront distribution (shown in the AWS console)."
  type        = string
}

variable "origin_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket to use as the CloudFront origin."
  type        = string
}

variable "origin_bucket_id" {
  description = "ID (name) of the S3 origin bucket, used as the CloudFront origin_id label."
  type        = string
}

variable "logging_bucket_domain_name" {
  description = "Domain name of the S3 bucket that will receive CloudFront standard access logs."
  type        = string
}

variable "price_class" {
  description = <<-EOT
    CloudFront price class controlling which edge locations are used.
    PriceClass_100 = North America + Europe only (cheapest).
    PriceClass_200 = adds Asia, Middle East, Africa.
    PriceClass_All = all edge locations worldwide.
  EOT
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "Object CloudFront returns for requests to the distribution's root URL."
  type        = string
  default     = "index.html"
}

variable "enabled" {
  description = <<-EOT
    Whether the distribution actively accepts end-user requests.
    Set to false to take the environment temporarily offline (e.g. once the
    challenge recording period has ended) without destroying the
    distribution, then back to true to bring it back without waiting for a
    full CloudFront re-provision.
  EOT
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the CloudFront distribution."
  type        = map(string)
  default     = {}
}
