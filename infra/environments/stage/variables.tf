variable "project_name" {
  description = "Short project slug used to prefix globally-unique resource names."
  type        = string
  default     = "fsl-devops-challenge"
}

variable "aws_region" {
  description = "AWS region resources are created in (CloudFront itself is global, but the S3 buckets and logging bucket need a home region)."
  type        = string
  default     = "us-east-1"
}

variable "enabled" {
  description = <<-EOT
    Whether the stage CloudFront distribution actively serves traffic.
    Set to false (without destroying the environment) once the challenge
    recording period has ended, satisfying the "accessible only during
    the challenge recording period" requirement while keeping the
    environment easy to switch back on.
  EOT
  type    = bool
  default = true
}

variable "log_retention_days" {
  description = "Number of days CloudFront access logs are retained before automatic expiration."
  type        = number
  default     = 30
}
