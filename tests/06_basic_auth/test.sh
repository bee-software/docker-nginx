#!/bin/bash
set -eux

export HTTP_PORT=30680
export HTTPS_PORT=30643

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

test "$(curl -s --fail -k https://localhost:$HTTPS_PORT/static.txt)" != "Hello World"
test "$(curl -s --fail --user wrongUser:password -k https://localhost:$HTTPS_PORT/static.txt)" != "Hello World"
test "$(curl -s --fail --user username:password -k https://localhost:$HTTPS_PORT/static.txt)" == "Hello World"
test "$(curl -s --fail --user anotherUser:password -k https://localhost:$HTTPS_PORT/static.txt)" == "Hello World"
