#!/bin/bash
set -eux

export HTTP_PORT=30780
export HTTPS_PORT=30743

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

curl -k -s --fail https://127.0.0.1:$HTTPS_PORT/request_headers.php

test "$(curl -k -s --fail https://127.0.0.1:$HTTPS_PORT/request_headers.php | grep '^X-Message:.*$' | head -n1)" != ""

