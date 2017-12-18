#!/bin/ash
set -e

echo "httpd listening on port ${PORT}..."
httpd -p ${PORT} -h /www -v -f
