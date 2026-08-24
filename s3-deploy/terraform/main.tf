# Publishes the CNAME Monitor dashboard as a public, read-only S3 static
# website. Run with your own AWS credentials (env vars, ~/.aws/credentials,
# AWS_PROFILE, or SSO) -- Terraform picks those up itself; nothing here
# handles or stores credentials.
#
# Usage:
#   terraform init
#   terraform apply -var="bucket_name=cname-monitor-yourname" -var="aws_region=us-east-1"

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "dashboard.html"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.site]
}

resource "aws_s3_object" "dashboard" {
  bucket       = aws_s3_bucket.site.id
  key          = "dashboard.html"
  source       = "${path.module}/../../dashboard.html"
  etag         = filemd5("${path.module}/../../dashboard.html")
  content_type = "text/html"

  cache_control = "no-cache"
}
