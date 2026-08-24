# CNAME Monitor dashboard on S3 (Terraform)

Publishes `dashboard.html` as a public, read-only S3 static website.

Run this yourself, wherever Terraform and the AWS CLI/SDK credential
chain are already set up (env vars, `~/.aws/credentials`, `AWS_PROFILE`,
SSO, etc.). Terraform picks up your credentials the normal way — nothing
in this config sees, stores, or needs them from Claude.

## What you get, and what you don't

- A public URL you (or anyone with the link) can open to check current
  CNAME status and history.
- **No HTTPS.** S3's built-in website hosting is HTTP-only — that's an S3
  limitation, not a Terraform one. Adding HTTPS means fronting the bucket
  with CloudFront, which is a separate, heavier setup this config doesn't
  do.
- Because there's no HTTPS, the "Connect config folder" button on the
  hosted copy won't work (that browser API needs a secure context).
  **Keep adding/editing/removing domains and settings from the
  locally-opened `dashboard.html`**, or by asking Claude — this S3 copy
  is a view-only mirror.
- The actual monitoring (scheduled DNS checks, history, email alerts)
  keeps running as the Cowork scheduled task against the local
  `cname-monitor` folder, unchanged. This just gives you another place to
  *view* a snapshot.

## Prerequisites

- Terraform >= 1.5.
- AWS CLI/SDK credentials already configured, with permission to create
  and configure S3 buckets (`s3:CreateBucket`, `s3:PutBucketPolicy`,
  `s3:PutBucketWebsite`, `s3:PutObject`, `s3:PutBucketPublicAccessBlock`,
  plus read equivalents).
- A globally-unique bucket name (S3 names are shared across every AWS
  account worldwide — lowercase, no underscores), e.g.
  `cname-monitor-yourname`.

## Deploy

```
cd terraform
terraform init
terraform apply -var="bucket_name=cname-monitor-yourname" -var="aws_region=us-east-1"
```

Terraform will print the website URL as an output when it finishes
(`website_endpoint`) — it reads the exact endpoint AWS assigns, so there's
no guessing about region-specific URL formats.

## Keeping it up to date

Just run `terraform apply` again with the same variables. The uploaded
object's checksum (`filemd5`) is tracked in state, so Terraform only
re-uploads `dashboard.html` when its contents have actually changed —
e.g. after the scheduled check runs, or after you edit domains locally
and regenerate the file with:

```
python3 ../../generate_dashboard.py ..
```

If you want this fully automatic, that means running `terraform apply`
on a schedule **on your own machine** (cron, CI, etc.) — not something
Claude can drive, since that would again require your AWS credentials to
be usable from somewhere Claude operates.

## Tear down

```
terraform destroy -var="bucket_name=cname-monitor-yourname" -var="aws_region=us-east-1"
```

Deletes the bucket and its contents.

## Notes

- If you'd rather not pass `-var` flags every time, create a
  `terraform.tfvars` file next to `main.tf`:

  ```
  bucket_name = "cname-monitor-yourname"
  aws_region  = "us-east-1"
  ```

  Terraform loads it automatically; just don't commit it anywhere public
  if the bucket name itself is sensitive (it usually isn't).
- A plain `aws s3` CLI version of this same deployment (`deploy.sh`,
  `sync.sh`, `teardown.sh`) is in the parent `s3-deploy` folder, if you'd
  rather not use Terraform for this.
