#!/bin/bash
set -ex

ENV_NAME_ARG=$1

MAIN_STACK_NAME=${ENV_NAME_ARG}
ECR_STACK_NAME=${ENV_NAME_ARG}-ecr
TEMPLATE_STORAGE_STACK_NAME=${ENV_NAME_ARG}-template-storage


###############################################################################
# Delete the S3 bucket used to store Cloud Formation templates. Cloud Formation
# won't delete a stack which provisioned an S3 bucket which is non-empty - so
# this must happen first.
#

aws s3 rb s3://${ENV_NAME_ARG} --force || true


###############################################################################
# Delete the ECR which holds our application's images. This must happen before
# the stack which provisoined the ECR is deleted.
#

aws ecr delete-repository --repository-name ${ENV_NAME_ARG} --force || true

###############################################################################
# Delete all the stacks we've created.
#

aws cloudformation delete-stack --stack-name ${ENV_NAME_ARG}-ecr || true
aws cloudformation delete-stack --stack-name ${ENV_NAME_ARG}-template-storage || true
aws cloudformation delete-stack --stack-name ${ENV_NAME_ARG} || true

aws cloudformation wait stack-delete-complete ${ECR_STACK_NAME}
aws cloudformation wait stack-delete-complete ${TEMPLATE_STORAGE_STACK_NAME}
aws cloudformation wait stack-delete-complete ${MAIN_STACK_NAME}

echo "$(date):${0##*/}:success"
