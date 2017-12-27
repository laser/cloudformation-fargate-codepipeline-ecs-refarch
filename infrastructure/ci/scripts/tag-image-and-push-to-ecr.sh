#!/bin/bash

set -e

ENV_NAME_ARG=$1

GIT_SHA=$(git rev-parse --verify HEAD)

set +x

$(aws ecr get-login --no-include-email --region us-east-1)

set -x

REPOSITORY_URI=$(
    aws ecr \
        describe-repositories \
        --region us-east-1 \
        --repository-names ${ENV_NAME_ARG} \
        --query 'repositories[0].repositoryUri' | sed -e 's;\";;g')

docker tag app_app ${REPOSITORY_URI}:latest
docker tag app_app ${REPOSITORY_URI}:${GIT_SHA}

docker push ${REPOSITORY_URI}:latest
docker push ${REPOSITORY_URI}:${GIT_SHA}
