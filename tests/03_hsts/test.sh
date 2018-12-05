#!/bin/bash
set -eux

export HTTP_PORT=30380
export HTTPS_PORT=30343

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

# test_hsts
test "$(curl --head -k -s --fail https://127.0.0.1:$HTTPS_PORT/ | grep '^Strict-Transport-Security:.*$' | head -n1 | tr -d '\r')" == 'Strict-Transport-Security: max-age=800; includeSubDomains'

# test_hsts_default
test "$(curl -k --head -s --resolve test2.example.org:$HTTPS_PORT:127.0.0.1 --fail https://test2.example.org:$HTTPS_PORT/ | grep '^Strict-Transport-Security:.*$' | head -n1 | tr -d '\r')" == 'Strict-Transport-Security: max-age=63072000; includeSubDomains'
