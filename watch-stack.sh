#!/bin/bash
set -e

ENV_NAME_ARG=$1

stack-status --watch --region us-east-1 --stack-name $ENV_NAME_ARG