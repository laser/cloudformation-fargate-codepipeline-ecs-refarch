#!/bin/ash

set -e

for CMD in "$@"
do
    ./scripts/${CMD}.sh
done
