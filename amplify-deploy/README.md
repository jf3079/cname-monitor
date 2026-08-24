# CNAME Monitor dashboard on AWS Amplify Hosting (Terraform)

Deploys `dashboard.html` to AWS Amplify Hosting as a manual ("no
repository") static site — this is AWS's own recommended way to host a
static site, and unlike plain S3 website hosting it gives you real HTTPS
and a CDN automatically, no CloudFront/ACM setup required.

Run this yourself, wherever Terraform and the AWS CLI are already
configured with your own credentials. Nothing here sees, stores, or
needs those credentials from Claude.

## Why this needs a helper script alongside Terraform

Amplify's manual-deploy flow (upload a zip, start the deployment job) is
an API action, not a piece of persistent infrastructure — there's no
native Terraform resource for "upload this file". So `main.tf` creates
the Amplify app and branch as real Terraform-managed resources, and a
`null_resource` with a `local-exec` provisioner runs `deploy_amplify.sh`
to actually push the content, using the AWS CLI. It only re-runs when
`dashboard.html`'s contents change (tracked via its MD5), so repeated
`terraform apply` runs are cheap no-ops until you have something new to
push.

## What you get, and what you don't

- A real `https://` URL (`<branch>.<appid>.amplifyapp.com`), fronted by
  CloudFront, with a valid cert Amplify manages for you.
- Because it's HTTPS, the "Connect config folder" button on this hosted
  copy *can* work in principle — but it still only has access to files
  on whatever device/browser you're using it from, so you'd need to pick
  the `cname-monitor` folder on that same machine. In practice it's
  easiest to keep managing domains from the locally-opened
  `dashboard.html` and treat the Amplify-hosted copy as a snapshot you
  refresh by re-running `terraform apply`.
- The actual monitoring (scheduled DNS checks, history, email alerts)
  keeps running as the Cowork scheduled task against the local
  `cname-monitor` folder, unchanged.

## Prerequisites

- Terraform >= 1.5.
- AWS CLI v2, `zip`, `curl`, and `python3` on the machine running
  `terraform apply` (the helper script uses all four).
- AWS credentials with Amplify permissions: `amplify:CreateApp`,
  `amplify:CreateBranch`, `amplify:CreateDeployment`,
  `amplify:StartDeployment`, `amplify:GetApp`, `amplify:GetBranch`,
  `amplify:DeleteApp` (for teardown), plus equivalent `Get`/`List`
  actions.
- Make the deploy script executable once: `chmod +x deploy_amplify.sh`.

## Deploy

```
terraform init
terraform apply -var="app_name=cname-monitor" -var="aws_region=us-east-1"
```

Terraform prints `website_url` when it finishes. The very first
deployment can take a minute or two to become reachable after the CLI
reports success — Amplify is provisioning the CDN distribution behind
the scenes.

## Updating it later

1. Get a fresh `dashboard.html` (e.g. after editing domains locally,
   run `python3 ../generate_dashboard.py ..` from this folder).
2. Re-run the same `terraform apply` command. The MD5 trigger detects
   the change and pushes a new deployment automatically; if nothing
   changed, it's a no-op.

## Tear down

```
terraform destroy -var="app_name=cname-monitor" -var="aws_region=us-east-1"
```

Deletes the Amplify app (and its branch/deployments) entirely.

## Notes

- If you'd rather not pass `-var` flags every time, put them in a
  `terraform.tfvars` file next to `main.tf`.
- The plain-S3 alternative (no HTTPS, but no Amplify permissions needed
  either) lives in the sibling `s3-deploy` folder, in both a bash-CLI
  and a Terraform flavor.
