#!/bin/bash
set -e

ENV_NAME_ARG=$1

IMAGE_TAG="$(aws ecr describe-repositories --query 'repositories[?repositoryName==`$ENV_NAME_ARG`].repositoryUri' | jq '.[0]'):latest"
REGION=$(aws configure get region)
STACK_NAME=$(aws cloudformation --region $REGION describe-stacks --query 'Stacks[0].Outputs[?OutputKey==`HelloworldServiceStackName`].OutputValue' --stack-name $ENV_NAME_ARG | jq '.[0]')
WORD="foooo"
TASK_FILE="./cloud-formation/build-$WORD.json"

echo $IMAGE_NAME
echo $REGION
echo $STACK_NAME

#sed -e "s;%IMAGE_TAG%;${IMAGE_TAG};g" ./cloud-formation/service-task-definition.json > $TASK_FILE
sed -i "s/\b%IMAGE_TAG%\b/${IMAGE_TAG}/g" ./cloud-formation/service-task-definition.json > $TASK_FILE

echo $TASK_FILE

#aws ecs register-task-definition --family $ENV_NAME_ARG --cli-input-json "file://$TASK_FILE"
