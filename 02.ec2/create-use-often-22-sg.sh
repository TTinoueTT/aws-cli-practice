#!/bin/bash
set -euo pipefail

# Variables
PREFIX="project"
ENV_VER="dev"
TAG_NAME="${PREFIX}-${ENV_VER}-ssh-sg"

## Security group
# ELB
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name ${TAG_NAME} \
    --description ${TAG_NAME} \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${TAG_NAME}}]" \
    --query "GroupId" --output text) && echo "$SECURITY_GROUP_ID"

MYIP=$(curl -s https://api.ipify.org)
aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --ip-permissions "[
            {
                \"IpProtocol\": \"tcp\",
                \"FromPort\": 22,
                \"ToPort\": 22,
                \"IpRanges\": [
                    {
                        \"CidrIp\": \"${MYIP}/32\",
                        \"Description\": \"self IP\"
                    }
                ]
            }
        ]"

aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --ip-permissions file://param/port-22-inbound-rule.json
