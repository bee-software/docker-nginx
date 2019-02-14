#!/bin/bash
set -eux

export HTTP_PORT=30080
export HTTPS_PORT=30043

cd $(dirname $0)
docker-compose up -d --build
${LEAVE_UP:-false} || trap "docker-compose stop -t 0; docker-compose rm -f -s -v" EXIT

get_certificate_common_name() {
    destination=$1

    openssl s_client -connect $destination </dev/null 2>/dev/null | grep ' 0 s:/' | sed 's/.*CN=\(.*\)/\1/g'
}

get_certificate_common_name_with_servername() {
    destination=$1
    servername=$2

    openssl s_client -servername $servername -connect $destination </dev/null 2>/dev/null | grep ' 0 s:/' | sed 's/.*CN=\(.*\)/\1/g'
}

assert_default_certificate() {
    local expected_common_name=$1

    test "$(get_certificate_common_name 127.0.0.1:$HTTPS_PORT)" == "$expected_common_name"
}

assert_sni_works() {
    test "$(get_certificate_common_name_with_servername 127.0.0.1:$HTTPS_PORT "test2.example.org")" == "test2.example.org"
}

assert_default_certificate "test.example.org"
assert_sni_works
