#!/bin/bash
set -e

get_stack_status () {
    aws cloudformation describe-stacks --stack-name $1 --query 'Stacks[0].StackStatus' | sed -e 's;\";;g'
}

stack_create_complete () {
    get_stack_status $1 | grep -m 1 "CREATE_COMPLETE" > /dev/null
}