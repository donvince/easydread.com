#!/bin/bash
# Deploy DNS stack — uses easydread profile (easydread-cli IAM user).
# Run whenever DNS records in infra/dns.yaml change.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

aws cloudformation deploy \
  --template-file "$SCRIPT_DIR/../infra/dns.yaml" \
  --stack-name easydread-dns \
  --profile easydread
