#!/bin/bash
# Delete existing Route 53 records so CF can own them after cf-deploy.sh.
# Run this ONCE before the first cf-deploy.sh. Do not run again after CF owns the records.
#
# Deletes: A, MX, TXT, www CNAME, ftp CNAME
# Leaves:  NS, SOA (Route 53 managed, cannot be deleted)
set -euo pipefail

HOSTED_ZONE_ID="Z05099481R278MSYRMTGJ"
PROFILE="don-root"

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --profile "$PROFILE" \
  --change-batch '{
    "Changes": [
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "easydread.com.",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [{"Value": "178.79.166.99"}]
        }
      },
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "easydread.com.",
          "Type": "MX",
          "TTL": 300,
          "ResourceRecords": [
            {"Value": "10 mx1.improvmx.com."},
            {"Value": "20 mx2.improvmx.com."}
          ]
        }
      },
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "easydread.com.",
          "Type": "TXT",
          "TTL": 300,
          "ResourceRecords": [{"Value": "\"v=spf1 include:spf.improvmx.com ~all\""}]
        }
      },
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "www.easydread.com.",
          "Type": "CNAME",
          "TTL": 300,
          "ResourceRecords": [{"Value": "easydread.com."}]
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
      }
    ]
  }'

echo "Records deleted. Run scripts/cf-deploy.sh to recreate under CF management."
