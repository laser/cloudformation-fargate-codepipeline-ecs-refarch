#!/bin/bash
set -e

stack-status --watch --region us-east-1 --stack-name $ENV_NAME
