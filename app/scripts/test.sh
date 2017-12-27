#!/bin/ash

set -e

echo "$(date):tests:running"
rails test
echo "$(date):tests:success"
