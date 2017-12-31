#!/bin/bash

set -ex

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

PRIVATE_SUBNETS=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnets`].OutputValue' \
        --stack-name ${ENV_NAME_ARG} | jq -r '.[0]')

ECS_SERVICE_SG=$(
    aws cloudformation \
        describe-stacks \
        --region us-east-1 \
        --query 'Stacks[0].Outputs[?OutputKey==`ECSServicesSecurityGroup`].OutputValue' \
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

TASK_DEFINITION_ARN=$(
    aws ecs \
        register-task-definition \
        --region us-east-1 \
        --family ${TASK_FAMILY_NAME} \
        --cpu 256 \
        --memory 512 \
        --requires-compatibilities FARGATE \
        --task-role-arn ${TASK_EXECUTION_ROLE_ARN} \
        --execution-role-arn ${TASK_EXECUTION_ROLE_ARN} \
        --network-mode awsvpc \
        --cli-input-json "file://${TASK_FILE}" | jq -r '.["taskDefinition"]["taskDefinitionArn"]')

MIGRATION_OVERRIDES_FILE="./migrations-$(date +%s).json"

sed -e "s;%TASK_CONTAINER_NAME%;${CONTAINER_NAME};g" \
    ./infrastructure/ci/templates/migration-overrides.json > ${MIGRATION_OVERRIDES_FILE}

MIGRATION_TASK_ARN=$(aws ecs run-task \
    --region us-east-1 \
    --cluster ${ENV_NAME_ARG} \
    --task-definition ${TASK_DEFINITION_ARN} \
    --overrides file://${MIGRATION_OVERRIDES_FILE} \
    --count 1 \
    --started-by migrations \
    --network-configuration awsvpcConfiguration="{subnets=[${PRIVATE_SUBNETS}],securityGroups=[${ECS_SERVICE_SG}],assignPublicIp=DISABLED}" \
    --launch-type FARGATE | jq -r '.["tasks"][0]["taskArn"]')

aws ecs wait tasks-stopped \
    --region us-east-1 \
    --cluster ${ENV_NAME_ARG} \
    --tasks ${MIGRATION_TASK_ARN}

MIGRATION_EXIT_CODE=$(aws ecs describe-tasks \
    --region us-east-1 \
    --cluster ${ENV_NAME_ARG} \
    --tasks ${MIGRATION_TASK_ARN} | jq -r '.["tasks"][0]["containers"][0]["exitCode"]')

rm ${TASK_FILE}
rm ${MIGRATION_OVERRIDES_FILE}

if [ "${MIGRATION_EXIT_CODE}" -eq "0" ] ; then
    aws ecs update-service \
        --region us-east-1 \
        --cluster ${ENV_NAME_ARG} \
        --service ${SERVICE_NAME} \
        --task-definition ${TASK_DEFINITION_ARN}
    echo "$(date):${0##*/}:success"
else
    echo "$(date):${0##*/}:failure:migrations-failed:${MIGRATION_TASK_ARN}"
    return ${MIGRATION_EXIT_CODE}
fi
