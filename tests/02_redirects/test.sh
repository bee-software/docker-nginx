#!/bin/bash
set -eux

export HTTP_PORT=30280
export HTTPS_PORT=30243

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

# in proxy mode
# test http redirects to https
test "$(curl --head -s -H 'Host: website.example.org' --fail http://127.0.0.1:$HTTP_PORT/index.html | grep '^Location:.*$' | head -n1 | tr -d '\r')" == 'Location: https://website.example.org/index.html'

# in redirect mode
# http redirects to backend
test "$(curl --head -s -H 'Host: test2.example.org' --fail http://127.0.0.1:$HTTP_PORT/index.html | grep '^Location:.*$' | head -n1 | tr -d '\r')" == 'Location: http://backend/index.html'

# https should redirect to backend
test "$(curl -k --head -s --resolve test2.example.org:$HTTPS_PORT:127.0.0.1 --fail https://test2.example.org:$HTTPS_PORT/index.html | grep '^Location:.*$' | head -n1 | tr -d '\r')" == 'Location: http://backend/index.html'
