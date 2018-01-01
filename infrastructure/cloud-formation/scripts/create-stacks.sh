#!/bin/bash
set -ex

. ./infrastructure/cloud-formation/scripts/shared-functions.sh --source-only

ENV_NAME_ARG=$1
GITHUB_USERNAME=$2
GITHUB_REPO=$3
GITHUB_BRANCH=$4
GITHUB_TOKEN=$5

###############################################################################
# Create an S3 stack which holds our CloudFormation templates and an ECR stack
# which will hold our application's Docker images
#

REPOSITORY_STACK_NAME=${ENV_NAME_ARG}-ecr
BUCKET_STACK_NAME=${ENV_NAME_ARG}-template-storage

aws cloudformation create-stack --stack-name ${REPOSITORY_STACK_NAME} \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./infrastructure/cloud-formation/templates/image-repository.yml \
    --parameters ParameterKey=RepositoryName,ParameterValue=${ENV_NAME_ARG}

aws cloudformation create-stack --stack-name ${BUCKET_STACK_NAME} \
    --template-body file://./infrastructure/cloud-formation/templates/template-storage.yml \
    --parameters ParameterKey=BucketName,ParameterValue=${ENV_NAME_ARG}

set +x
until stack_create_complete ${REPOSITORY_STACK_NAME}; do
    echo "$(date):${REPOSITORY_STACK_NAME}:$(get_stack_status ${REPOSITORY_STACK_NAME})"
    sleep 1
done

until stack_create_complete ${BUCKET_STACK_NAME}; do
    echo "$(date):${BUCKET_STACK_NAME}:$(get_stack_status ${BUCKET_STACK_NAME})"
    sleep 1
done
set -x


###############################################################################
# Ensure that S3 has the most recent revision of our CloudFormation templates
#

aws s3 sync \
    --acl public-read \
    --delete \
    ./infrastructure/cloud-formation/templates/ s3://${ENV_NAME_ARG}/infrastructure/cloud-formation/templates/


###############################################################################
# Build the application and push to ECR
#

docker-compose -p websvc -f ./websvc/docker-compose.yml build

$(aws ecr get-login --no-include-email --region us-east-1)

REPOSITORY_URI=$(aws ecr \
    describe-repositories \
    --region us-east-1 \
    --query "repositories[?repositoryName==\`${ENV_NAME_ARG}\`].repositoryUri" \
    | jq -r '.[0]')

docker tag websvc_websvc ${REPOSITORY_URI}:latest

docker push ${REPOSITORY_URI}:latest

###############################################################################
# Create the main stack (which relies upon the built image in ECR)
#

RAILS_SECRET_KEY_BASE=$(docker-compose -p websvc -f ./websvc/docker-compose.yml run --rm websvc "rails secret")

REPOSITORY_ARN=$(aws ecr \
    describe-repositories \
    --region us-east-1 \
    --query "repositories[?repositoryName==\`${ENV_NAME_ARG}\`].repositoryArn" \
    | jq -r '.[0]')

aws cloudformation create-stack --stack-name ${ENV_NAME_ARG} \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./infrastructure/cloud-formation/templates/master.yml \
    --parameters \
        ParameterKey=GitHubRepo,ParameterValue=${GITHUB_REPO}\
        ParameterKey=GitHubToken,ParameterValue=${GITHUB_TOKEN} \
        ParameterKey=GitHubUser,ParameterValue=${GITHUB_USERNAME} \
        ParameterKey=GitHubBranch,ParameterValue=${GITHUB_BRANCH} \
        ParameterKey=RepositoryUri,ParameterValue=${REPOSITORY_URI} \
        ParameterKey=RepositoryArn,ParameterValue=${REPOSITORY_ARN} \
        ParameterKey=RailsSecretKeyBase,ParameterValue=${RAILS_SECRET_KEY_BASE} \
        ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/${ENV_NAME_ARG}/infrastructure/cloud-formation/templates/

until stack_create_complete $ENV_NAME_ARG; do
    echo "$(date):${ENV_NAME_ARG}:$(get_stack_status ${ENV_NAME_ARG})"
    sleep 1
done

echo "$(date):${0##*/}:success"
