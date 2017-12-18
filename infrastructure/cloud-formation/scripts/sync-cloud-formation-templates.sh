#!/bin/bash
set -e

ENV_NAME_ARG=$1

S3_URL="s3://$ENV_NAME_ARG/infrastructure/cloud-formation/templates/"

aws s3 sync ./infrastructure/cloud-formation/templates/ $S3_URL --acl public-read --delete

echo "$(date):${0##*/}:success"