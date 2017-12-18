#!/bin/bash
set -e

. ./infrastructure/cloud-formation/scripts/shared-functions.sh --source-only

ENV_NAME_ARG=$1

REPOSITORY_STACK_NAME=${ENV_NAME_ARG}-ecr
BUCKET_STACK_NAME=${ENV_NAME_ARG}-s3

aws cloudformation create-stack --stack-name ${REPOSITORY_STACK_NAME} \
    --template-body file://./infrastructure/cloud-formation/templates/image-repository.yml \
    --parameters ParameterKey=RepositoryName,ParameterValue=${ENV_NAME_ARG}

aws cloudformation create-stack --stack-name ${BUCKET_STACK_NAME} \
    --template-body file://./infrastructure/cloud-formation/templates/template-storage.yml \
    --parameters ParameterKey=BucketName,ParameterValue=${ENV_NAME_ARG}

until stack_create_complete ${REPOSITORY_STACK_NAME}; do
    echo "$(date):${REPOSITORY_STACK_NAME}:$(get_stack_status ${REPOSITORY_STACK_NAME})"
    sleep 1
done

until stack_create_complete $BUCKET_STACK_NAME; do
    echo "$(date):${BUCKET_STACK_NAME}:$(get_stack_status ${BUCKET_STACK_NAME})"
    sleep 1
done

echo "$(date):${0##*/}:success"