variable "app_name" {
  description = "Name for the Amplify app."
  type        = string
  default     = "cname-monitor"
}

variable "aws_region" {
  description = "AWS region to create the Amplify app in."
  type        = string
  default     = "us-east-1"
}
