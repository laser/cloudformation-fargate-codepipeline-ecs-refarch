#!/bin/bash
set -ex

ENV_NAME_ARG=$1
GITHUB_USERNAME=$2
GITHUB_REPO=$3
GITHUB_BRANCH=$4
GITHUB_TOKEN=$5

###############################################################################
# Create an S3 stack which holds our CloudFormation templates and an ECR stack
# which will hold our application's Docker images
#

BUCKET_STACK_NAME=${ENV_NAME_ARG}-template-storage

aws cloudformation create-stack --stack-name ${BUCKET_STACK_NAME} \
    --template-body file://./infrastructure/cloud-formation/templates/template-storage.yml \
    --parameters ParameterKey=BucketName,ParameterValue=${ENV_NAME_ARG}

aws cloudformation wait stack-create-complete --stack-name ${BUCKET_STACK_NAME}


###############################################################################
# Ensure that S3 has the most recent revision of our CloudFormation templates
#

aws s3 sync \
    --acl public-read \
    --delete \
    ./infrastructure/cloud-formation/templates/ s3://${ENV_NAME_ARG}/infrastructure/cloud-formation/templates/


###############################################################################
# Create the stack
#

RAILS_SECRET_KEY_BASE=$(docker-compose -p websvc -f ./websvc/docker-compose.yml run --rm websvc "rails secret" | tr -d "\n\r")

aws cloudformation create-stack --stack-name ${ENV_NAME_ARG} \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./infrastructure/cloud-formation/templates/master.yml \
    --parameters \
        ParameterKey=GitHubRepo,ParameterValue=${GITHUB_REPO}\
        ParameterKey=GitHubToken,ParameterValue=${GITHUB_TOKEN} \
        ParameterKey=GitHubUser,ParameterValue=${GITHUB_USERNAME} \
        ParameterKey=GitHubBranch,ParameterValue=${GITHUB_BRANCH} \
        ParameterKey=RailsSecretKeyBase,ParameterValue=${RAILS_SECRET_KEY_BASE} \
        ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/${ENV_NAME_ARG}/infrastructure/cloud-formation/templates/

aws cloudformation wait stack-create-complete --stack-name ${ENV_NAME_ARG}

echo "$(date):${0##*/}:success"
