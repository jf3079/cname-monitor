#!/usr/bin/env bash
# Deletes the bucket and everything in it. Irreversible.
#
# Usage:
#   ./teardown.sh <bucket-name> [aws-profile]

set -euo pipefail

BUCKET="${1:?Usage: ./teardown.sh <bucket-name> [aws-profile]}"
PROFILE_ARG=()
if [ -n "${2:-}" ]; then
  PROFILE_ARG=(--profile "$2")
fi

read -r -p "This will permanently delete s3://$BUCKET and all its contents. Type the bucket name to confirm: " CONFIRM
if [ "$CONFIRM" != "$BUCKET" ]; then
  echo "Confirmation did not match. Aborting."
  exit 1
fi

aws s3 rb "s3://$BUCKET" --force "${PROFILE_ARG[@]}"
echo "Deleted s3://$BUCKET"
