#!/bin/bash
set -eux

export HTTP_PORT=30180
export HTTPS_PORT=30143

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

test "$(curl --fail -s --resolve test.example.org:$HTTPS_PORT:127.0.0.1 -k https://test.example.org:$HTTPS_PORT/timeout_10s.php)" == ""
test "$(curl --fail -s --resolve test2.example.org:$HTTPS_PORT:127.0.0.1 -k https://test2.example.org:$HTTPS_PORT/timeout_10s.php)" == "Good!"
