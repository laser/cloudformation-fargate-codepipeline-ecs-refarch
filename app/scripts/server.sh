#!/bin/ash

set -e

rake tmp:clear
ruby ./scripts/wait-for-db ${DATABASE_URL}
rails server -b 0.0.0.0
