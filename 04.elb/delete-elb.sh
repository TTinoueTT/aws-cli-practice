#!/bin/bash
set -euo pipefail

# ロードバランサーの ARN を取得
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='cloud01-alb'].LoadBalancerArn" \
  --output text) && echo "$ALB_ARN"

# リスナーの削除
# shellcheck disable=SC2207
LISTENER_ARNS=($(aws elbv2 describe-listeners \
  --load-balancer-arn "$ALB_ARN" \
  --query "Listeners[*].ListenerArn" \
  --output text)) && echo "${LISTENER_ARNS[@]}"

# リスナーの削除
for LA in "${LISTENER_ARNS[@]}"; do
  aws elbv2 delete-listener --listener-arn "$LA" && echo "Deleted Listener: $LA"
done

# ターゲットグループの取得
# shellcheck disable=SC2207
TARGET_GROUPS_ARNS=($(aws elbv2 describe-target-groups \
  --load-balancer-arn "$ALB_ARN" \
  --query "TargetGroups[*].TargetGroupArn" \
  --output text)) && echo "${TARGET_GROUPS_ARNS[@]}"

# ターゲットグループの削除
for TGA in "${TARGET_GROUPS_ARNS[@]}"; do
  aws elbv2 delete-target-group --target-group-arn "$TGA" && echo "Deleted TargetGroup: $TGA"
done

# ELB の削除
aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN"