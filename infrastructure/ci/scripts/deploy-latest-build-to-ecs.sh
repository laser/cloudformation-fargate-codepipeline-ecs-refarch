#!/bin/bash

set -e

ENV_NAME_ARG=$1

IMAGE_TAG=$(
    aws ecr \
        describe-repositories \
        --region us-east-1 \
        --repository-names ${ENV_NAME_ARG} \
        --query 'repositories[0].repositoryUri' | sed -e 's;\";;g'):latest

SERVICE_ARN=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`WebServiceArn`].OutputValue' \
        --stack-name ${ENV_NAME_ARG} | jq -r '.[0]')

LOG_GROUP_NAME=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`WebServiceLogGroupName`].OutputValue' \
        --stack-name ${ENV_NAME_ARG} | jq -r '.[0]')

TASK_EXECUTION_ROLE_ARN=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`WebServiceTaskExecutionRoleArn`].OutputValue' \
        --stack-name ${ENV_NAME_ARG} | jq -r '.[0]')

TASK_FAMILY_NAME=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`WebServiceTaskFamilyName`].OutputValue' \
        --stack-name ${ENV_NAME_ARG} | jq -r '.[0]')

CONTAINER_NAME=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`WebServiceContainerName`].OutputValue' \
        --stack-name ${ENV_NAME_ARG} | jq -r '.[0]')

DATABASE_URL=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`DBURL`].OutputValue' \
        --stack-name ${ENV_NAME_ARG} | jq -r '.[0]')

SERVICE_REGION=$(echo ${SERVICE_ARN} | sed -e "s;.*ecs:;;g" -e "s;:.*;;g")

SERVICE_NAME=$(echo ${SERVICE_ARN} | sed -e "s;.*/;;g")

TASK_FILE="./build-$(date +%s).json"

sed -e "s;%IMAGE_TAG%;${IMAGE_TAG};g" \
    -e "s;%AWSLOGS_GROUP%;${LOG_GROUP_NAME};g" \
    -e "s;%AWSLOGS_REGION%;${SERVICE_REGION};g" \
    -e "s;%DATABASE_URL%;${DATABASE_URL};g" \
    -e "s;%TASK_FAMILY_NAME%;${TASK_FAMILY_NAME};g" \
    -e "s;%TASK_CONTAINER_NAME%;${CONTAINER_NAME};g" \
    -e "s;%COMMAND_JSON_ARRAY%;\[\"server\"];g" \
    ./infrastructure/ci/templates/task-definition.json > ${TASK_FILE}

cat ${TASK_FILE}

set -x

TASK_REVISION=$(
    aws ecs \
        register-task-definition \
        --region us-east-1 \
        --family web-service \
        --cpu 256 \
        --memory 512 \
        --requires-compatibilities FARGATE \
        --task-role-arn ${TASK_EXECUTION_ROLE_ARN} \
        --execution-role-arn ${TASK_EXECUTION_ROLE_ARN} \
        --network-mode awsvpc \
        --cli-input-json "file://${TASK_FILE}" | jq '.["taskDefinition"]["revision"]')

aws ecs update-service --region us-east-1 --cluster ${ENV_NAME_ARG} --service ${SERVICE_NAME} --task-definition web-service:${TASK_REVISION}

set +x

rm ${TASK_FILE}

echo "$(date):${0##*/}:success"
