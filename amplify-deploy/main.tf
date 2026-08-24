# Deploys the CNAME Monitor dashboard to AWS Amplify Hosting as a manual
# ("no repository") static deployment -- Amplify gives HTTPS and a CDN
# out of the box, which is why this is used instead of plain S3 website
# hosting.
#
# Run with your own AWS credentials already configured (env vars,
# ~/.aws/credentials, AWS_PROFILE, SSO, etc.) -- Terraform and the AWS CLI
# pick those up themselves; nothing here handles or stores them.
#
# Requires, on the machine running `terraform apply`: AWS CLI v2, zip,
# curl, python3 (used only to parse a small JSON response, no packages
# needed).
#
# Usage:
#   terraform init
#   terraform apply -var="app_name=cname-monitor" -var="aws_region=us-east-1"

provider "aws" {
  region = var.aws_region
}

resource "aws_amplify_app" "site" {
  name     = var.app_name
  platform = "WEB"
  # No `repository` block: this app is deployed manually (zip upload) via
  # the null_resource below, rather than from a connected git repo.
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.site.id
  branch_name = "main"
  stage       = "PRODUCTION"
}

# Amplify's manual-deploy flow (CreateDeployment -> upload zip ->
# StartDeployment) is an API action, not persistent infrastructure, so
# there's no native Terraform resource for it. This drives it through the
# AWS CLI instead, and only re-runs when dashboard.html's content changes.
resource "null_resource" "deploy" {
  triggers = {
    dashboard_md5 = filemd5("${path.module}/../dashboard.html")
  }

  provisioner "local-exec" {
    command = "${path.module}/deploy_amplify.sh \"${aws_amplify_app.site.id}\" \"${aws_amplify_branch.main.branch_name}\" \"${path.module}/../dashboard.html\" \"${var.aws_region}\""
  }

  depends_on = [aws_amplify_branch.main]
}
