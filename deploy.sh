#!/bin/bash
set -e

ENV_NAME_ARG=$1

IMAGE_TAG=$(
    aws ecr \
        describe-repositories \
        --repository-names $ENV_NAME_ARG \
        --query 'repositories[0].repositoryUri' | sed -e 's;\";;g'):latest

SERVICE_ARN=$(
    aws cloudformation \
        describe-stacks \
        --query 'Stacks[0].Outputs[?OutputKey==`HelloworldServiceArn`].OutputValue' \
        --stack-name $ENV_NAME_ARG | jq '.[0]' | sed -e "s;\";;g")

STACK_NAME=$(
    aws cloudformation \
        describe-stacks \
        --query 'Stacks[0].Outputs[?OutputKey==`HelloworldServiceStackName`].OutputValue' \
        --stack-name $ENV_NAME_ARG | jq '.[0]' | sed -e "s;\";;g")

SERVICE_REGION=$(echo $SERVICE_ARN | sed -e "s;.*ecs:;;g" -e "s;:.*;;g")

SERVICE_NAME=$(echo $SERVICE_ARN | sed -e "s;.*/;;g")

TASK_FILE="./cloud-formation/build-$(date +%s).json"

sed -e "s;%IMAGE_TAG%;$IMAGE_TAG;g" \
    -e "s;%STACK_NAME%;$STACK_NAME;g" \
    -e "s;%AWSLOGS_REGION%;$SERVICE_REGION;g" \
    ./cloud-formation/task-definition.json > $TASK_FILE

TASK_REVISION=$(aws ecs register-task-definition --family helloworld-service --cli-input-json "file://$TASK_FILE" | jq '.["taskDefinition"]["revision"]')

aws ecs update-service --cluster $ENV_NAME_ARG --service $SERVICE_NAME --task-definition helloworld-service:$TASK_REVISION

rm $TASK_FILE