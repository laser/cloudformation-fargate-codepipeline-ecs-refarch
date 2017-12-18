#!/bin/bash
set -e

ENV_NAME_ARG=$1

LOAD_BALANCER_URL=$(
    aws cloudformation \
        describe-stacks \
        --query 'Stacks[0].Outputs[?OutputKey==`HelloworldServiceUrl`].OutputValue' \
        --stack-name $ENV_NAME_ARG | jq '.[0]' | sed -e "s;\";;g")

echo "polling API - press [CTRL+C] to stop"

while :
do
    curl $LOAD_BALANCER_URL
    echo -e '\n'$(date)
	sleep 1
done