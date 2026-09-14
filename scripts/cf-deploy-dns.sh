#!/bin/bash
# Cut Route 53 over to the existing CloudFront distribution.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DISTRIBUTION_DOMAIN_NAME="$(aws cloudformation describe-stacks \
  --stack-name easydread-hosting \
  --region us-east-1 \
  --profile don-easydread \
  --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" \
  --output text)"

aws cloudformation deploy \
  --template-file "$SCRIPT_DIR/../infra/dns.yaml" \
  --stack-name easydread-dns \
  --parameter-overrides "DistributionDomainName=$DISTRIBUTION_DOMAIN_NAME" \
  --region eu-west-1 \
  --profile don-easydread
