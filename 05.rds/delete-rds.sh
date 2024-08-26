#!/bin/bash
set -euo pipefail

RDS_IDENTIFIER="cloud01-db-instance"

PARAMETER_GROUP_NAME=$(aws rds describe-db-instances \
  --region ap-northeast-1 \
  --db-instance-identifier $RDS_IDENTIFIER \
  --query "DBInstances[*].DBParameterGroups[*].DBParameterGroupName" \
  --output text) && echo "$PARAMETER_GROUP_NAME"

SUBNET_GROUP_NAME=$(aws rds describe-db-instances \
  --region ap-northeast-1 \
  --db-instance-identifier $RDS_IDENTIFIER \
  --query "DBInstances[*].DBSubnetGroup.DBSubnetGroupName" \
  --output text) && echo "$SUBNET_GROUP_NAME"

# 削除保護の無効化
aws rds modify-db-instance \
  --db-instance-identifier $RDS_IDENTIFIER \
  --no-deletion-protection

# インスタンスの削除
aws rds delete-db-instance \
  --db-instance-identifier $RDS_IDENTIFIER \
  --skip-final-snapshot

# 削除待機
aws rds wait db-instance-deleted \
  --db-instance-identifier $RDS_IDENTIFIER

# パラメータグループの削除
aws rds delete-db-parameter-group \
  --db-parameter-group-name "$PARAMETER_GROUP_NAME"

# サブネットグループの削除
aws rds delete-db-subnet-group \
  --db-subnet-group-name "$SUBNET_GROUP_NAME"

# TODO: インスタンス削除後のため未検証
# オプショングループの削除
aws rds delete-option-group \
  --option-group-name "cloud01-option-group"

# CloudWatch, ロググループの削除
# shellcheck disable=SC2207
LOG_GROUPS=($(aws logs describe-log-groups \
  --query "logGroups[?contains(logGroupName, 'cloud01-db-instance')].logGroupName" \
  --output text)) && echo "${LOG_GROUPS[@]}"

# Iterate over each log group name
for LOG_GROUP_NAME in "${LOG_GROUPS[@]}"; do
  aws logs delete-log-group --log-group-name "$LOG_GROUP_NAME" && echo "Deleted log group: $LOG_GROUP_NAME"
done


