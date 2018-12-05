#!/bin/bash
set -eux

export HTTP_PORT=30580
export HTTPS_PORT=30543

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

test "$(curl -k -s --resolve test3.example.org:$HTTPS_PORT:127.0.0.1 --fail https://test3.example.org:$HTTPS_PORT/hello/request_headers.php | grep '^Host:.*$' | head -n1)" == $'Host: test3.example.org'
