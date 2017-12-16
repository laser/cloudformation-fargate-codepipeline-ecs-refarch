#!/bin/bash
set -e

REPOSITORY_STACK_NAME=$ENV_NAME-ecr
BUCKET_STACK_NAME=$ENV_NAME-s3

aws cloudformation create-stack --stack-name $REPOSITORY_STACK_NAME \
    --template-body file://./cloud-formation/image-repository.yml \
    --parameters ParameterKey=RepositoryName,ParameterValue=$ENV_NAME

echo "created ECR stack: $REPOSITORY_STACK_NAME"

aws cloudformation create-stack --stack-name $BUCKET_STACK_NAME \
    --template-body file://./cloud-formation/template-storage.yml \
    --parameters ParameterKey=BucketName,ParameterValue=$ENV_NAME

echo "created S3 stack: $BUCKET_STACK_NAME"
