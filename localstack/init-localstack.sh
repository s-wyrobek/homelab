#!/bin/bash

set -euo pipefail

echo "Initalization LocalStack... "

#Settings
ENDPOINT="http://localhost.localstack.cloud:4566"
AWS_CMD="aws --endpoint-url=$ENDPOINT"

#Health Check
wait_for_localstack() {
  echo "Waiting for LocalStack..."
  until curl -s "$ENDPOINT/_localstack/health" | grep -qE '"s3": "(available|running)"'; do
    sleep 2
  done
  echo "LocalStack up"
}

wait_for_localstack

#S3
echo "Creating buckets..."
$AWS_CMD s3 mb s3://app-logs
$AWS_CMD s3 mb s3://app-backups
echo "Buckets ready"

#IAM
echo "Creating IAM user"
$AWS_CMD iam create-user --user-name szymon-cloud-engineer
$AWS_CMD iam attach-user-policy \
   --user-name szymon-cloud-engineer \
   --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
echo "IAM ready"

#SQS
echo "Creating SQS queue..."
$AWS_CMD sqs create-queue --queue-name app-events
echo "SQS ready"

echo "Creating DynamoDB table..."
$AWS_CMD dynamodb create-table \
  --table-name app-data \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
echo "DynamoDB ready"

echo "---------------------------------"
echo "------LocalStack Initialized-----"
echo "---------------------------------"
echo "S3:       app-logs, app-backups"
echo "IAM:      app-user (S3FullAccess)"
echo "SQS:      app-events"
echo "DynamoDB: app-data"
echo "---------------------------------"
