#!/bin/bash
set -ex

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

#aws cloudformation create-stack --stack-name ${ENV_NAME_ARG} \
aws cloudformation deploy \
    --stack-name ${ENV_NAME_ARG} \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-file ./infrastructure/cloud-formation/templates/master.yml

echo "$(date):${0##*/}:success"
