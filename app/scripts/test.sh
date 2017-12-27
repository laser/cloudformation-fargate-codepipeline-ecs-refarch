#!/bin/ash

set -e

ruby ./scripts/wait-for-db ${DATABASE_URL}
rails test
