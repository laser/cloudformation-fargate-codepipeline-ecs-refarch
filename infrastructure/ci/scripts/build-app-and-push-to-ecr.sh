#!/bin/bash
set -e

ENV_NAME_ARG=$1

GIT_SHA=$(git rev-parse --verify HEAD)

$(aws ecr get-login --no-include-email --region us-east-1)

REPOSITORY_URI=$(
    aws ecr \
        describe-repositories \
        --repository-names ${ENV_NAME_ARG} \
        --query 'repositories[0].repositoryUri' | sed -e 's;\";;g')

docker build -t ${ENV_NAME_ARG} ./app/.

docker tag ${ENV_NAME_ARG} ${REPOSITORY_URI}:latest
docker tag ${ENV_NAME_ARG} ${REPOSITORY_URI}:${GIT_SHA}

docker push ${REPOSITORY_URI}:latest
docker push ${REPOSITORY_URI}:${GIT_SHA}

echo "$(date):${0##*/}:success"