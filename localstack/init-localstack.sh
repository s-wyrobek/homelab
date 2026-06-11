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

create_bucket_if_not_exists() {
  if $AWS_CMD s3 ls s3://$1 &>/dev/null; then
    echo "$1 already exists"
  else
    echo "Creating $1..."
    $AWS_CMD s3 mb s3://$1
  fi
}
create_bucket_if_not_exists app-logs
create_bucket_if_not_exists app-backups



#IAM

create_user_if_not_exists() {
  if $AWS_CMD iam get-user --user-name $1 &>/dev/null; then
    echo "$1 already exists"
  else
    echo "Creating IAM user"
      $AWS_CMD iam create-user --user-name $1
      $AWS_CMD iam attach-user-policy \
        --user-name $1 \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
      echo "IAM ready"
  fi
}
create_user_if_not_exists szymon-cloud-engineer



#SQS

create_sqs_if_not_exists() {
  if $AWS_CMD sqs get-queue-url --queue-name $1 &>/dev/null; then
    echo "$1 already exists"
  else 
    echo "Creating SQS queue..."
    $AWS_CMD sqs create-queue --queue-name $1
    echo "SQS ready"
  fi
}
create_sqs_if_not_exists app-events

create_dynamodb_if_not_exists() {
  if $AWS_CMD dynamodb describe-table --table-name $1 &>/dev/null; then
    echo "$1 already exists"
  else
    echo "Creating DynamoDB table..."
    $AWS_CMD dynamodb create-table \
      --table-name $1 \
      --attribute-definitions AttributeName=id,AttributeType=S \
      --key-schema AttributeName=id,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST
    echo "DynamoDB ready"
  fi
}
create_dynamodb_if_not_exists app-table

echo "---------------------------------"
echo "------LocalStack Initialized-----"
echo "---------------------------------"
echo "S3:       app-logs, app-backups"
echo "IAM:      app-user (S3FullAccess)"
echo "SQS:      app-events"
echo "DynamoDB: app-data"
echo "---------------------------------"
