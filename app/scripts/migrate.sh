#!/bin/ash

set -e

echo "$(date):migrations:running"
rails db:migrate
echo "$(date):migrations:success"
