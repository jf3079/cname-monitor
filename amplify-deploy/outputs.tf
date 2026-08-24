output "amplify_app_id" {
  value = aws_amplify_app.site.id
}

output "default_domain" {
  description = "Amplify's generated domain for this app."
  value       = aws_amplify_app.site.default_domain
}

output "website_url" {
  description = "HTTPS URL for the dashboard once the deployment finishes."
  value       = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.site.default_domain}/dashboard.html"
}
