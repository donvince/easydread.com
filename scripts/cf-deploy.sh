#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../infra/easydread.yaml"

aws cloudformation deploy \
  --template-file "$TEMPLATE" \
  --stack-name easydread \
  --capabilities CAPABILITY_NAMED_IAM \
  --profile don-root
