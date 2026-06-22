variable "environment" {
  description = "Short environment name, e.g. devel or stage. Used to namespace bucket names and resource tags."
  type        = string

  validation {
    condition     = contains(["devel", "stage"], var.environment)
    error_message = "environment must be one of: devel, stage."
  }
}

variable "project_name" {
  description = "Short project slug used as a prefix for globally-unique resource names (e.g. S3 bucket names)."
  type        = string
}

variable "enabled" {
  description = "Whether the CloudFront distribution is actively serving traffic. Set to false to take the environment offline without destroying it."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudFront access logs."
  type        = number
  default     = 30
}

variable "price_class" {
  description = "CloudFront price class. See modules/cloudfront/variables.tf for details."
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Common tags applied to all resources in this environment."
  type        = map(string)
  default     = {}
}
