#!/bin/bash
# DNS cutover: easydread.com → GitHub Pages
#
# Changes:
#   easydread.com A     178.79.166.99 → 4x GitHub Pages IPs
#   www CNAME           easydread.com. → donvince.github.io.
#   ftp CNAME           easydread.com. → A record 178.79.166.99 (type change)
#
# Unchanged: MX, TXT/SPF, NS, SOA
set -euo pipefail

HOSTED_ZONE_ID="Z05099481R278MSYRMTGJ"
PROFILE="don-root"

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --profile "$PROFILE" \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "easydread.com.",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {"Value": "185.199.108.153"},
            {"Value": "185.199.109.153"},
            {"Value": "185.199.110.153"},
            {"Value": "185.199.111.153"}
          ]
        }
      },
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "www.easydread.com.",
          "Type": "CNAME",
          "TTL": 300,
          "ResourceRecords": [{"Value": "donvince.github.io."}]
        }
      },
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "ftp.easydread.com.",
          "Type": "CNAME",
          "TTL": 300,
          "ResourceRecords": [{"Value": "easydread.com."}]
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "ftp.easydread.com.",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [{"Value": "178.79.166.99"}]
        }
      }
    ]
  }'
