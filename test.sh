#!/bin/bash
set -eux

get_certificate_common_name() {
    destination=$1

    openssl s_client -connect $destination </dev/null 2>/dev/null | grep ' 0 s:/' | sed 's/.*CN=\(.*\)/\1/g'
}

get_certificate_common_name_with_servername() {
    destination=$1
    servername=$2

    openssl s_client -servername $servername -connect $destination </dev/null 2>/dev/null | grep ' 0 s:/' | sed 's/.*CN=\(.*\)/\1/g'
}

test_http_redirects() {
    test "$(curl --head -s -H 'Host: website.example.org' --fail http://127.0.0.1:33080/index.html | grep '^Location:.*$' | head -n1)" == $'Location: https://website.example.org/index.html\r'
}

test_hsts() {
    test "$(curl --head -k -s --fail https://127.0.0.1:33443/ | grep '^Strict-Transport-Security:.*$' | head -n1)" == $'Strict-Transport-Security: max-age=800\r'
}

assert_default_certificate() {
    local expected_common_name=$1

    test $(get_certificate_common_name 127.0.0.1:33443) == "$expected_common_name"
}

assert_sni_works() {
    test $(get_certificate_common_name_with_servername 127.0.0.1:33443 "test2.example.org") == "test2.example.org"
}

curl -s --fail -k https://127.0.0.1:33443/ > /dev/null

test_http_redirects
test_hsts
assert_default_certificate "test.example.org"
assert_sni_works