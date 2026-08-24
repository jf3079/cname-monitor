# Hosting the CNAME Monitor dashboard on S3

This publishes `dashboard.html` as a public, read-only static website using
S3's built-in "static website hosting" feature.

**Run these scripts on a machine where the AWS CLI is already configured**
with your own credentials (`aws configure`, an SSO profile, etc.). Claude
cannot see, enter, or use your AWS credentials — that has to happen on your
end.

## What you get, and what you don't

- A public URL anyone with the link can open to view current CNAME status
  and history. Good for checking from your phone or sharing with a
  teammate.
- **No HTTPS.** The plain S3 website endpoint is HTTP-only (that's an S3
  limitation, not something this script can work around — CloudFront is the
  usual fix, but that's a separate, heavier setup).
- Because there's no HTTPS, the "Connect config folder" feature on the
  hosted copy won't work (the browser API it uses requires a secure
  context). **Keep adding/editing/removing domains and settings from the
  locally-opened `dashboard.html`** (or by asking Claude in chat) — the S3
  copy is a view-only mirror.
- The actual monitoring (hourly DNS checks, history, email alerts) keeps
  running as the scheduled task in Cowork, writing to the local
  `cname-monitor` folder, exactly as before. This S3 setup doesn't change
  that — it just gives you an extra place to *view* a snapshot of the
  results.

## One-time setup

1. Make sure the AWS CLI v2 is installed and `aws sts get-caller-identity`
   works (i.e. you're already logged in / configured).
2. Your IAM user or role needs permission to create/configure S3 buckets:
   `s3:CreateBucket`, `s3:PutBucketPolicy`, `s3:PutBucketWebsite`,
   `s3:PutObject`, `s3:PutBucketPublicAccessBlock`.
3. Pick a globally-unique bucket name (S3 bucket names are shared across
   all AWS accounts worldwide, lowercase, no underscores) — e.g.
   `cname-monitor-yourname`.
4. From this `s3-deploy` folder, run:

   ```
   chmod +x deploy.sh sync.sh teardown.sh
   ./deploy.sh cname-monitor-yourname us-east-1
   ```

   (swap in your preferred region, and add a third argument if you use a
   named AWS CLI profile: `./deploy.sh cname-monitor-yourname us-east-1 my-profile`)

5. The script prints a likely website URL, but region-based endpoint
   formats vary — confirm the exact one in the S3 console under
   **your bucket → Properties → Static website hosting**.

## Keeping it up to date

The S3 copy is a snapshot from whenever you last uploaded it. To refresh
it after the scheduled check runs (or after you've edited domains
locally and want the public view to match):

```
./sync.sh cname-monitor-yourname
```

If you want this automatic, you'd wire that command into a cron job or
scheduler **on your own machine** (not through Claude, since that would
again require your AWS credentials to live somewhere Claude operates).

## Tearing it down

```
./teardown.sh cname-monitor-yourname
```

Deletes the bucket and everything in it. Asks for confirmation first.
