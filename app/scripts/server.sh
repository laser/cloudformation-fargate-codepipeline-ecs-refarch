#!/bin/ash

set -e

rake tmp:clear
rails server -b 0.0.0.0
