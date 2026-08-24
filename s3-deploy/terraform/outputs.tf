output "website_endpoint" {
  description = "HTTP URL for the static site (no HTTPS -- see README)."
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}/dashboard.html"
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}
