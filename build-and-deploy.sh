#!/bin/bash
set -e

eval aws ecr get-login --no-include-email --region us-east-1
docker build . -t cloudformationecsdockercircleci_web:latest
docker tag cloudformationecsdockercircleci_web:latest "166875342547.dkr.ecr.us-east-1.amazonaws.com/$ENV_NAME"
docker push "166875342547.dkr.ecr.us-east-1.amazonaws.com/$ENV_NAME"


