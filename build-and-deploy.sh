#!/bin/bash
set -e

$(aws ecr get-login --no-include-email --region us-east-1)
docker build -t "$ENV_NAME" .
docker tag "$ENV_NAME:latest" "166875342547.dkr.ecr.us-east-1.amazonaws.com/$ENV_NAME:latest"
docker push "166875342547.dkr.ecr.us-east-1.amazonaws.com/$ENV_NAME:latest"


