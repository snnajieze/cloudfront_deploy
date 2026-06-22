variable "bucket_name" {
  description = "Globally unique name for the S3 bucket that will store CloudFront access logs."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain access log objects before they are automatically expired."
  type        = number
  default     = 30
}
