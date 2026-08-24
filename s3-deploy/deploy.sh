#!/usr/bin/env bash
# Deploys dashboard.html as a public S3 static website.
# Run this on a machine where the AWS CLI is already configured
# (`aws configure` or an SSO profile) with your own credentials.
# Claude never sees or handles those credentials.
#
# Usage:
#   ./deploy.sh <bucket-name> <region> [aws-profile]
#
# Example:
#   ./deploy.sh cname-monitor-jerome us-east-1
#   ./deploy.sh cname-monitor-jerome eu-west-1 my-sso-profile

set -euo pipefail

BUCKET="${1:?Usage: ./deploy.sh <bucket-name> <region> [aws-profile]}"
REGION="${2:?Usage: ./deploy.sh <bucket-name> <region> [aws-profile]}"
PROFILE_ARG=()
if [ -n "${3:-}" ]; then
  PROFILE_ARG=(--profile "$3")
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD="$SCRIPT_DIR/../dashboard.html"

if [ ! -f "$DASHBOARD" ]; then
  echo "Could not find dashboard.html at $DASHBOARD" >&2
  echo "Run this script from inside the s3-deploy folder, next to the cname-monitor folder." >&2
  exit 1
fi

echo "== Creating bucket s3://$BUCKET in $REGION =="
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$BUCKET" "${PROFILE_ARG[@]}" \
    --region "$REGION" 2>/dev/null || echo "(bucket may already exist, continuing)"
else
  aws s3api create-bucket --bucket "$BUCKET" "${PROFILE_ARG[@]}" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null || echo "(bucket may already exist, continuing)"
fi

echo "== Allowing public access on the bucket =="
aws s3api put-public-access-block --bucket "$BUCKET" "${PROFILE_ARG[@]}" \
  --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

echo "== Enabling static website hosting (index: dashboard.html) =="
aws s3 website "s3://$BUCKET/" "${PROFILE_ARG[@]}" --index-document dashboard.html

echo "== Applying public-read bucket policy =="
sed "s/BUCKET_NAME/$BUCKET/g" "$SCRIPT_DIR/bucket-policy.template.json" > "$SCRIPT_DIR/.bucket-policy.generated.json"
aws s3api put-bucket-policy --bucket "$BUCKET" "${PROFILE_ARG[@]}" \
  --policy "file://$SCRIPT_DIR/.bucket-policy.generated.json"
rm -f "$SCRIPT_DIR/.bucket-policy.generated.json"

echo "== Uploading dashboard.html =="
aws s3 cp "$DASHBOARD" "s3://$BUCKET/dashboard.html" "${PROFILE_ARG[@]}" \
  --content-type "text/html" --cache-control "no-cache"

echo
echo "Done. Website endpoint format depends on region; check the exact URL under:"
echo "  S3 console -> $BUCKET -> Properties -> Static website hosting"
echo
echo "Likely endpoint (verify in console):"
if [ "$REGION" = "us-east-1" ]; then
  echo "  http://$BUCKET.s3-website-us-east-1.amazonaws.com/dashboard.html"
else
  echo "  http://$BUCKET.s3-website.$REGION.amazonaws.com/dashboard.html"
  echo "  (some regions instead use: http://$BUCKET.s3-website-$REGION.amazonaws.com/dashboard.html)"
fi
echo
echo "Note: this is a read-only mirror over plain HTTP. Add/edit/remove-domain"
echo "controls on this page won't work there (they need HTTPS) -- keep managing"
echo "the domain list from the locally-opened dashboard.html or by asking Claude."
echo "Re-run ./sync.sh $BUCKET [profile] any time you want to push a fresh snapshot."
