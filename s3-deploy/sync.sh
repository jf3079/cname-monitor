#!/usr/bin/env bash
# Re-uploads the current dashboard.html to an already-deployed S3 bucket.
# Run this any time after the local dashboard has fresh data (e.g. after
# the scheduled check runs, or after editing domains) and you want the
# S3-hosted snapshot to reflect it.
#
# Usage:
#   ./sync.sh <bucket-name> [aws-profile]

set -euo pipefail

BUCKET="${1:?Usage: ./sync.sh <bucket-name> [aws-profile]}"
PROFILE_ARG=()
if [ -n "${2:-}" ]; then
  PROFILE_ARG=(--profile "$2")
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD="$SCRIPT_DIR/../dashboard.html"

if [ ! -f "$DASHBOARD" ]; then
  echo "Could not find dashboard.html at $DASHBOARD" >&2
  exit 1
fi

aws s3 cp "$DASHBOARD" "s3://$BUCKET/dashboard.html" "${PROFILE_ARG[@]}" \
  --content-type "text/html" --cache-control "no-cache"

echo "Synced $(date -u +%Y-%m-%dT%H:%M:%SZ)"
