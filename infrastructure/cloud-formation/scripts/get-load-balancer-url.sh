#!/bin/bash
set -e

ENV_NAME_ARG=$1

curl $(aws cloudformation \
        describe-stacks \
        --query 'Stacks[0].Outputs[?OutputKey==`HelloworldServiceUrl`].OutputValue' \
        --stack-name $ENV_NAME_ARG | jq '.[0]' | sed -e "s;\";;g")