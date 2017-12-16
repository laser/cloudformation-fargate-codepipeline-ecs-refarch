#!/bin/bash
set -e

ENV_NAME_ARG=$1

S3_URL="s3://$ENV_NAME_ARG/template-storage/"

aws s3 sync ./cloud-formation $S3_URL --acl public-read --delete
