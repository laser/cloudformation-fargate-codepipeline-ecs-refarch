#!/bin/bash
set -e

. ./infrastructure/cloud-formation/scripts/shared-functions.sh --source-only

ENV_NAME_ARG=$1

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

aws cloudformation update-stack --stack-name $ENV_NAME_ARG \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./infrastructure/cloud-formation/templates/master.yml \
    --parameters "ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/$ENV_NAME_ARG/infrastructure/cloud-formation/templates/"

until stack_create_complete $ENV_NAME_ARG; do
    echo "$(date):${ENV_NAME_ARG}:$(get_stack_status ${ENV_NAME_ARG})"
    sleep 1
done

echo "$(date):${0##*/}:success"
