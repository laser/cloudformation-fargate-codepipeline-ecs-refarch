#!/bin/bash
set -e

ENV_NAME_ARG=$1

$(aws ecr get-login --no-include-email --region us-east-1)

IMAGE_TAG=$(
    aws ecr \
        describe-repositories \
        --repository-names $ENV_NAME_ARG \
        --query 'repositories[0].repositoryUri' | sed -e 's;\";;g'):latest

docker build -t "$ENV_NAME_ARG" .
docker tag "$ENV_NAME_ARG:latest" $IMAGE_TAG
docker push $IMAGE_TAG