#!/bin/bash
set -ex

. ./infrastructure/cloud-formation/scripts/shared-functions.sh --source-only

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

RAILS_SECRET_KEY_BASE=$(docker-compose -p websvc -f ./websvc/docker-compose.yml run --rm websvc "rails secret" | tr -d '\r')

REPOSITORY_URI=$(aws ecr \
    describe-repositories \
    --region us-east-1 \
    --query "repositories[?repositoryName==\`${ENV_NAME_ARG}\`].repositoryUri" \
    | jq -r '.[0]')

REPOSITORY_ARN=$(aws ecr \
    describe-repositories \
    --region us-east-1 \
    --query "repositories[?repositoryName==\`${ENV_NAME_ARG}\`].repositoryArn" \
    | jq -r '.[0]')

aws cloudformation update-stack --stack-name ${ENV_NAME_ARG} \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./infrastructure/cloud-formation/templates/master.yml \
    --parameters \
        ParameterKey=GitHubRepo,ParameterValue=${GITHUB_REPO}\
        ParameterKey=GitHubBranch,ParameterValue=${GITHUB_BRANCH} \
        ParameterKey=GitHubToken,ParameterValue=${GITHUB_TOKEN} \
        ParameterKey=GitHubUser,ParameterValue=${GITHUB_USERNAME} \
        ParameterKey=RepositoryUri,ParameterValue=${REPOSITORY_URI} \
        ParameterKey=RepositoryArn,ParameterValue=${REPOSITORY_ARN} \
        ParameterKey=RailsSecretKeyBase,ParameterValue=${RAILS_SECRET_KEY_BASE} \
        ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/${ENV_NAME_ARG}/infrastructure/cloud-formation/templates/

set +x
until stack_create_complete $ENV_NAME_ARG; do
    echo "$(date):${ENV_NAME_ARG}:$(get_stack_status ${ENV_NAME_ARG})"
    sleep 1
done
set -x

echo "$(date):${0##*/}:success"
