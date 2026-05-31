#!/bin/bash
# Deploy IAM stack — requires don-root profile (needs IAM + CF permissions).
# Run once on setup, or when IAM permissions change.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

aws cloudformation deploy \
  --template-file "$SCRIPT_DIR/../infra/iam.yaml" \
  --stack-name easydread-iam \
  --capabilities CAPABILITY_NAMED_IAM \
  --profile don-root
