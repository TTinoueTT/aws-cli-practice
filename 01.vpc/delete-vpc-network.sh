#!/bin/bash
set -euo pipefail

# ひとまず作っているが、臨機応変に対応する
PREFIX="cloud01"
# ルートテーブルの関連 ID を取得
# shellcheck disable=SC2207
ASSOCIATION_IDS=($(aws ec2 describe-route-tables \
    --filters "Name=tag:Name,Values=${PREFIX}*" \
    --query "RouteTables[].Associations[].RouteTableAssociationId" \
    --output text)) && echo "${ASSOCIATION_IDS[@]}"

for ASSOC_ID in "${ASSOCIATION_IDS[@]}"; do
    aws ec2 disassociate-route-table \
        --association-id "$ASSOC_ID"
done

# ルートテーブルの削除
# shellcheck disable=SC2207
ROUTE_TABLE_IDS=($(aws ec2 describe-route-tables \
    --filters "Name=tag:Name,Values=${PREFIX}*" \
    --query "RouteTables[].RouteTableId" \
    --output text)) && echo "${ROUTE_TABLE_IDS[@]}"

for RT_ID in "${ROUTE_TABLE_IDS[@]}"; do
    aws ec2 delete-route-table \
        --route-table-id "$RT_ID"
done

# サブネットの削除
# shellcheck disable=SC2207
SUBNET_IDS=($(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=${PREFIX}*" \
    --query "Subnets[].SubnetId" \
    --output text)) && echo "${SUBNET_IDS[@]}"

for SUBNET_ID in "${SUBNET_IDS[@]}"; do
    aws ec2 delete-subnet \
        --subnet-id "$SUBNET_ID"
done

# IGW の VPC の関連付けを解除 ~ インターネットゲートウェイの削除
VPC_ID=$(aws ec2 describe-internet-gateways \
    --filters "Name=tag:Name,Values=${PREFIX}*" \
    --query "InternetGateways[].Attachments[].VpcId" \
    --output text) && echo "$VPC_ID"

INTERNET_GATEWAY_ID=$(aws ec2 describe-internet-gateways \
    --filters "Name=tag:Name,Values=${PREFIX}*" \
    --query "InternetGateways[].InternetGatewayId" \
    --output text) && echo "$INTERNET_GATEWAY_ID"

aws ec2 detach-internet-gateway \
    --internet-gateway-id "$INTERNET_GATEWAY_ID" \
    --vpc-id "$VPC_ID"

aws ec2 delete-internet-gateway \
    --internet-gateway-id "$INTERNET_GATEWAY_ID"

# セキュリティグループの削除
# shellcheck disable=SC2207
SECURITY_GROUP_IDS=($(aws ec2 describe-security-groups \
    --filters "Name=tag:Name,Values=${PREFIX}*" \
    --query "SecurityGroups[].GroupId" \
    --output text)) && echo "${SECURITY_GROUP_IDS[@]}"

for SG_ID in "${SECURITY_GROUP_IDS[@]}"; do
    aws ec2 delete-security-group --group-id "$SG_ID"
done

# VPC の削除
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=${PREFIX}*" \
    --query "Vpcs[].VpcId" \
    --output text) && echo "$VPC_ID"

aws ec2 delete-vpc --vpc-id "$VPC_ID"
