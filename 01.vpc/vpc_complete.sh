#!/bin/bash
set -euo pipefail

# Variables
PREFIX="project"
ENV_VER="dev"
TAG_PREFIX="${PREFIX}-${ENV_VER}"

# VPC
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --instance-tenancy default \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${TAG_PREFIX}-vpc}]"

VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=${TAG_PREFIX}-vpc" \
    --query "Vpcs[*].VpcId" \
    --output text) && echo "$VPC_ID"

# InternetGateway
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${TAG_PREFIX}-igw}]" \
    --query "InternetGateway.InternetGatewayId" \
    --output text) && echo "$INTERNET_GATEWAY_ID"

aws ec2 attach-internet-gateway \
    --internet-gateway-id "$INTERNET_GATEWAY_ID" \
    --vpc-id "$VPC_ID"

# Public subnet
PUBLIC_SUBNET_1a_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.11.0/24 \
    --availability-zone ap-northeast-1a \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${TAG_PREFIX}-public-subnet-1a}]" \
    --query "Subnet.SubnetId" \
    --output text)

PUBLIC_SUBNET_1c_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.12.0/24 \
    --availability-zone ap-northeast-1c \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${TAG_PREFIX}-public-subnet-1c}]" \
    --query "Subnet.SubnetId" \
    --output text)

# Public routeTable
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${TAG_PREFIX}-public-route}]" \
    --query "RouteTable.RouteTableId" \
    --output text)

aws ec2 create-route \
    --route-table-id "$ROUTE_TABLE_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$INTERNET_GATEWAY_ID"

aws ec2 associate-route-table \
    --route-table-id "$ROUTE_TABLE_ID" \
    --subnet-id "$PUBLIC_SUBNET_1a_ID"

aws ec2 associate-route-table \
    --route-table-id "$ROUTE_TABLE_ID" \
    --subnet-id "$PUBLIC_SUBNET_1c_ID"
