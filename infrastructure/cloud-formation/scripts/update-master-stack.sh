#!/bin/bash
set -ex

ENV_NAME_ARG=$1
GITHUB_USERNAME=$2
GITHUB_REPO=$3
GITHUB_BRANCH=$4
GITHUB_TOKEN=$5

###############################################################################
# Ensure that S3 has the most recent revision of our CloudFormation templates
#

aws s3 sync \
    --acl public-read \
    --delete \
    ./infrastructure/cloud-formation/templates/ s3://${ENV_NAME_ARG}/infrastructure/cloud-formation/templates/

###############################################################################
# Update our stack using the S3-hosted Cloud Formation templates.
#

RAILS_SECRET_KEY_BASE=$(aws cloudformation describe-stacks \
    --stack-name yulanitude \
    --query 'Stacks[0].Parameters[?ParameterKey==`RailsSecretKeyBase`].ParameterValue' \
    | jq -r '.[0]')

aws cloudformation update-stack --stack-name ${ENV_NAME_ARG} \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./infrastructure/cloud-formation/templates/master.yml \
    --parameters \
        ParameterKey=GitHubRepo,ParameterValue=${GITHUB_REPO}\
        ParameterKey=GitHubBranch,ParameterValue=${GITHUB_BRANCH} \
        ParameterKey=GitHubToken,ParameterValue=${GITHUB_TOKEN} \
        ParameterKey=GitHubUser,ParameterValue=${GITHUB_USERNAME} \
        ParameterKey=RailsSecretKeyBase,ParameterValue=${RAILS_SECRET_KEY_BASE} \
        ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/${ENV_NAME_ARG}/infrastructure/cloud-formation/templates/

aws cloudformation wait stack-update-complete --stack-name ${ENV_NAME_ARG}

echo "$(date):${0##*/}:success"
