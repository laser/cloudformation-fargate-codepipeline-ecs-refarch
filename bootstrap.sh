#!/bin/bash
set -e

ENV_NAME_ARG=$1

REPOSITORY_STACK_NAME=$ENV_NAME_ARG-ecr
BUCKET_STACK_NAME=$ENV_NAME_ARG-s3

aws cloudformation create-stack --stack-name $REPOSITORY_STACK_NAME \
    --template-body file://./cloud-formation/image-repository.yml \
    --parameters ParameterKey=RepositoryName,ParameterValue=$ENV_NAME_ARG

echo "created ECR stack: $REPOSITORY_STACK_NAME"

aws cloudformation create-stack --stack-name $BUCKET_STACK_NAME \
    --template-body file://./cloud-formation/template-storage.yml \
    --parameters ParameterKey=BucketName,ParameterValue=$ENV_NAME_ARG

echo "created S3 stack: $BUCKET_STACK_NAME"
