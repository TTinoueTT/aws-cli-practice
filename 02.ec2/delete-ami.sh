#!/bin/bash
set -euo pipefail

# ACCOUNT_ID=$(aws sts get-caller-identity \
#   --query Account \
#   --output text) && echo "$ACCOUNT_ID"

# aws ec2 describe-images \
#   --owners self \
#   --filters "Name=tag:Name,Values=*cloud01-web*" \
#   --query "Images[*].BlockDeviceMappings[*].EBS[*].SnapshotId"
NAME_REGEX="*cloud01-web*"

AMI_ID=$(aws ec2 describe-images \
    --owners self \
    --filters "Name=tag:Name,Values=*cloud01-web*" \
    --query "Images[*].ImageId" \
    --output text) && echo "$AMI_ID"

aws ec2 deregister-image --image-id "$AMI_ID"

# aws ec2   describe-image-attribute \
#   --attribute <value> \
#   --image-id "$AMI_ID"

# スナップショットのの削除
# ボリュームの削除

# shellcheck disable=SC2207
INSTANCE_IDS=($(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$NAME_REGEX" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)) && echo "${INSTANCE_IDS[@]}"

aws ec2 terminate-instances --instance-ids "${INSTANCE_IDS[@]}"
