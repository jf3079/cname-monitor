#!/usr/bin/env bash
# Called by Terraform (local-exec) to push a manual deployment to an
# existing Amplify app/branch. Not meant to be run standalone, but it's
# just a script -- feel free to run it directly too:
#
#   ./deploy_amplify.sh <app-id> <branch-name> <path-to-dashboard.html> <region>

set -euo pipefail

APP_ID="${1:?app id required}"
BRANCH="${2:?branch name required}"
DASHBOARD_SRC="${3:?path to dashboard.html required}"
REGION="${4:?region required}"

if [ ! -f "$DASHBOARD_SRC" ]; then
  echo "Could not find dashboard.html at $DASHBOARD_SRC" >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Amplify serves whatever's at the root as "/", so ship the file as both
# index.html (root URL works) and dashboard.html (keeps the familiar name).
cp "$DASHBOARD_SRC" "$TMPDIR/index.html"
cp "$DASHBOARD_SRC" "$TMPDIR/dashboard.html"

ZIP_PATH="$TMPDIR/site.zip"
(cd "$TMPDIR" && zip -q "$ZIP_PATH" index.html dashboard.html)

echo "Creating Amplify deployment for app $APP_ID / branch $BRANCH..."
DEPLOY_JSON="$(aws amplify create-deployment --app-id "$APP_ID" --branch-name "$BRANCH" --region "$REGION")"

JOB_ID="$(python3 -c "import sys, json; print(json.loads(sys.argv[1])['jobId'])" "$DEPLOY_JSON")"
UPLOAD_URL="$(python3 -c "import sys, json; print(json.loads(sys.argv[1])['zipUploadUrl'])" "$DEPLOY_JSON")"

echo "Uploading site bundle (job $JOB_ID)..."
curl -sS -X PUT "$UPLOAD_URL" --upload-file "$ZIP_PATH" -H "Content-Type: application/zip"

echo "Starting deployment..."
aws amplify start-deployment --app-id "$APP_ID" --branch-name "$BRANCH" --job-id "$JOB_ID" --region "$REGION" >/dev/null

echo "Deployment started. Check status with:"
echo "  aws amplify get-job --app-id $APP_ID --branch-name $BRANCH --job-id $JOB_ID --region $REGION"
