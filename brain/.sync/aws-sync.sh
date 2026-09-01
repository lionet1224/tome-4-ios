#!/usr/bin/env bash
# aws-sync.sh — read-only AWS inventory pull for the TrewUp brain.
#
# Snapshots a core set of resources per region and drops timestamped Markdown
# into .raw/aws/ for the wiki-ingest step. Designed to be SAFE: only list/describe
# (read-only) calls, never create/modify/delete.
#
# Coverage is intentionally a CORE set (see SERVICES below). What is NOT covered
# is logged at the end so the snapshot never reads as "complete" when it isn't —
# extend the SERVICES block as the engagement needs more.
#
# Requires: aws CLI v2, jq. Uses the profile in sources.json (a read-only role).
# Usage:    bash .sync/aws-sync.sh
#
# UNTESTED until AWS access lands — verify the first run by eye, and confirm the
# profile is read-only (ReadOnlyAccess / ViewOnlyAccess) before running.

set -euo pipefail

SYNC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="$(dirname "$SYNC_DIR")"
CFG="$SYNC_DIR/sources.json"
OUT="$VAULT/.raw/aws"
STAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"

command -v aws >/dev/null || { echo "ERR: aws CLI not installed"; exit 1; }
command -v jq  >/dev/null || { echo "ERR: jq not installed"; exit 1; }

PROFILE=$(jq -r '.aws.profile' "$CFG")
export AWS_PROFILE="$PROFILE"

# Identity / sanity check
ident=$(aws sts get-caller-identity 2>/dev/null) || { echo "ERR: aws auth failed for profile '$PROFILE'"; exit 1; }
echo "AWS sync as: $(echo "$ident" | jq -r '.Arn')"

mkdir -p "$OUT"
REGIONS=$(jq -r '.aws.regions[]' "$CFG")

# A safe read-only call run with `|| true` so one missing permission/service
# never aborts the whole snapshot.
q() { aws --output json "$@" 2>/dev/null || echo '"(unavailable — permission or service not enabled)"'; }

dest="$OUT/inventory__${STAMP}.md"
{
  echo "# AWS inventory — TrewUp"
  echo "_synced: $STAMP — profile: ${PROFILE}_"
  echo
  echo "## Account identity"
  echo '```json'; echo "$ident"; echo '```'
  echo
  echo "## Account-wide (region-agnostic)"
  echo "### S3 buckets"; echo '```json'; q s3api list-buckets --query 'Buckets[].Name'; echo '```'
  echo "### IAM summary"; echo '```json'; q iam get-account-summary; echo '```'
  echo "### IAM roles (names only)"; echo '```json'; q iam list-roles --query 'Roles[].RoleName'; echo '```'
  echo

  for R in $REGIONS; do
    echo "## Region: $R"
    echo "### EC2 instances"; echo '```json'
    q ec2 describe-instances --region "$R" \
      --query 'Reservations[].Instances[].{id:InstanceId,type:InstanceType,state:State.Name,name:Tags[?Key==`Name`]|[0].Value}'
    echo '```'
    echo "### VPCs"; echo '```json'
    q ec2 describe-vpcs --region "$R" --query 'Vpcs[].{id:VpcId,cidr:CidrBlock,default:IsDefault}'; echo '```'
    echo "### Lambda functions"; echo '```json'
    q lambda list-functions --region "$R" --query 'Functions[].{name:FunctionName,runtime:Runtime,updated:LastModified}'; echo '```'
    echo "### RDS instances"; echo '```json'
    q rds describe-db-instances --region "$R" --query 'DBInstances[].{id:DBInstanceIdentifier,engine:Engine,class:DBInstanceClass,status:DBInstanceStatus}'; echo '```'
    echo "### ECS clusters"; echo '```json'
    q ecs list-clusters --region "$R" --query 'clusterArns'; echo '```'
    echo "### EKS clusters"; echo '```json'
    q eks list-clusters --region "$R" --query 'clusters'; echo '```'
    echo "### All tagged resources (broad sweep)"; echo '```json'
    q resourcegroupstaggingapi get-resources --region "$R" --query 'ResourceTagMappingList[].ResourceARN'; echo '```'
    echo
  done

  echo "## NOT covered by this snapshot"
  echo "Extend the SERVICES block in aws-sync.sh to add these as the engagement needs them:"
  echo "- API Gateway, CloudFront, Route53, ELB/ALB, SQS/SNS, DynamoDB, ElastiCache"
  echo "- CloudFormation/CDK/Terraform stacks, Secrets Manager / SSM Parameter names (NOT values)"
  echo "- CloudWatch alarms, Config rules, GuardDuty/SecurityHub findings, CloudTrail trails"
  echo "- Cost/usage (Cost Explorer), Organizations structure (multi-account expansion)"
} > "$dest"

echo "wrote $dest"

# Stamp last_sync
tmp=$(mktemp)
jq ".aws.last_sync = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$CFG" > "$tmp" && mv "$tmp" "$CFG"
echo "Done. Next: ingest .raw/aws/ into the wiki (see .sync/ROUTINE.md)."
