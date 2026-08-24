variable "bucket_name" {
  description = "Globally-unique S3 bucket name for the dashboard (lowercase, no underscores)."
  type        = string
}

variable "aws_region" {
  description = "AWS region to create the bucket in."
  type        = string
  default     = "us-east-1"
}
