variable "bucket_name" {
  description = "Globally unique name for the S3 bucket that will store the built static application."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
