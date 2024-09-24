#!/bin/bash
set -euo pipefail

LAMBDA_ROLE=LambdaTranslateFullAccessRole

ROLE_ARN=$(aws iam get-role \
    --role-name $LAMBDA_ROLE \
    --query 'Role.Arn' \
    --output text) && echo "$ROLE_ARN"

# 変数が空かどうかチェック
if [[ "$ROLE_ARN" == *"$LAMBDA_ROLE"* ]]; then
    echo "exist iam role $LAMBDA_ROLE"
else
    echo "do not exist $LAMBDA_ROLE"
    # lambda 実行ロールを作成
    aws iam create-role \
        --role-name $LAMBDA_ROLE \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                        "Service": "lambda.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
        }'
    # ポリシーのアタッチ
    aws iam attach-role-policy \
        --role-name $LAMBDA_ROLE \
        --policy-arn arn:aws:iam::aws:policy/TranslateFullAccess

    ROLE_ARN=$(aws iam get-role \
        --role-name LambdaTranslateFullAccessRole \
        --query 'Role.Arn' \
        --output text) && echo "$ROLE_ARN"
fi

aws lambda create-function \
    --function-name TranslateFunction \
    --runtime python3.12 \
    --role "$ROLE_ARN" \
    --handler function.translate_v1.lambda_handler \
    --zip-file fileb://function.zip

aws lambda invoke \
    --function-name TranslateFunction \
    output.txt

exit
# 更新する場合
# aws lambda update-function-code \
#     --function-name translate-function \
#     --zip-file fileb://function.zip
