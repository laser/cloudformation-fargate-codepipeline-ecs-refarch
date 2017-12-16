#!/bin/bash
set -e

ENV_NAME_ARG=$1

$(aws ecr get-login --no-include-email --region us-east-1)
docker build -t "$ENV_NAME_ARG" .
docker tag "$ENV_NAME_ARG:latest" "166875342547.dkr.ecr.us-east-1.amazonaws.com/$ENV_NAME_ARG:latest"
docker push "166875342547.dkr.ecr.us-east-1.amazonaws.com/$ENV_NAME_ARG:latest"


