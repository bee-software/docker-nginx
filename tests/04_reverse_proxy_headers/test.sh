#!/bin/bash
set -eux

export HTTP_PORT=30480
export HTTPS_PORT=30443

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

test_x_real_ip() {
    [[ "$(curl -k -s --fail https://127.0.0.1:$HTTPS_PORT/request_headers.php | grep '^X-Real-IP:.*$' | head -n1)" =~ ^X-Real-IP:\ 172.*$ ]]
}

test_x_forwarded_proto() {
    test "$(curl -k -s --fail https://127.0.0.1:$HTTPS_PORT/request_headers.php | grep '^X-Forwarded-Proto:.*$' | head -n1)" == $'X-Forwarded-Proto: https'
}

test_x_forwarded_for() {
    [[ "$(curl -k -s --fail https://127.0.0.1:$HTTPS_PORT/request_headers.php | grep '^X-Forwarded-For:.*$' | head -n1)" =~ ^X-Forwarded-For:\ 172.*$ ]]
}

test_x_forwarded_host() {
    test "$(curl -k -s --fail -H "Host: test.com" https://127.0.0.1:$HTTPS_PORT/request_headers.php | grep '^X-Forwarded-Host:.*$' | head -n1)" == "X-Forwarded-Host: test.com:443" # This is the actual port nginx is listening on. See docker-compose.yml.
}

test_host() {
    test "$(curl -k -s --fail -H "Host: test.com" https://127.0.0.1:$HTTPS_PORT/request_headers.php | grep '^Host:.*$' | head -n1)" == $'Host: test.com'
}

test_x_real_ip
test_x_forwarded_proto
test_x_forwarded_for
test_x_forwarded_host
test_host
