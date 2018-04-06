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
    test "$(curl --head -k -s --fail https://127.0.0.1:33443/ | grep '^Strict-Transport-Security:.*$' | head -n1 | tr -d '\r')" == 'Strict-Transport-Security: max-age=800; includeSubDomains'
}

test_hsts_default() {
    test "$(curl -k --head -s --resolve test2.example.org:33443:127.0.0.1 --fail https://test2.example.org:33443/index.html | grep '^Strict-Transport-Security:.*$' | head -n1 | tr -d '\r')" == 'Strict-Transport-Security: max-age=63072000; includeSubDomains'
}

test_x_real_ip() {
    [[ "$(curl -k -s --fail https://127.0.0.1:33443/request_headers.php | grep '^X-Real-IP:.*$' | head -n1)" =~ ^X-Real-IP:\ 172.*$ ]]
}

test_x_forwarded_proto() {
    test "$(curl -k -s --fail https://127.0.0.1:33443/request_headers.php | grep '^X-Forwarded-Proto:.*$' | head -n1)" == $'X-Forwarded-Proto: https'
}

test_x_forwarded_for() {
    [[ "$(curl -k -s --fail https://127.0.0.1:33443/request_headers.php | grep '^X-Forwarded-For:.*$' | head -n1)" =~ ^X-Forwarded-For:\ 172.*$ ]]
}

test_host() {
    test "$(curl -k -s --fail -H "Host: test.com" https://127.0.0.1:33443/request_headers.php | grep '^Host:.*$' | head -n1)" == $'Host: test.com'
}

assert_default_certificate() {
    local expected_common_name=$1

    test $(get_certificate_common_name 127.0.0.1:33443) == "$expected_common_name"
}

assert_sni_works() {
    test $(get_certificate_common_name_with_servername 127.0.0.1:33443 "test2.example.org") == "test2.example.org"
}

test_redirect_mode_redirects_to_configured_backend() {
    # http redirects to backend
    test "$(curl --head -s -H 'Host: test2.example.org' --fail http://127.0.0.1:33080/index.html | grep '^Location:.*$' | head -n1)" == $'Location: http://backend/index.html\r'

    # https should redirect to backend
    test "$(curl -k --head -s --resolve test2.example.org:33443:127.0.0.1 --fail https://test2.example.org:33443/index.html | grep '^Location:.*$' | head -n1)" == $'Location: http://backend/index.html\r'
}

test_frontend_url() {
    test "$(curl -k -s --resolve test3.example.org:33443:127.0.0.1 --fail https://test3.example.org:33443/hello/request_headers.php | grep '^Host:.*$' | head -n1)" == $'Host: test3.example.org'
}

test_timeout_after_5_seconds_on_test_example_org(){
    ! curl --fail --head -s -H 'Host: test.example.org' -k \
        https://127.0.0.1:33443/timeout_10s.php > /dev/null
}

test_don_t_timeout_after_10_seconds_on_test3_example_org(){
    curl --fail -s -H 'Host: test3.example.org' -k \
        https://127.0.0.1:33443/hello/timeout_10s.php > /dev/null
}

curl -s --fail -k https://127.0.0.1:33443/ > /dev/null

test_timeout_after_5_seconds_on_test_example_org
test_don_t_timeout_after_10_seconds_on_test3_example_org
test_http_redirects
test_hsts
test_hsts_default
test_x_real_ip
test_x_forwarded_proto
test_x_forwarded_for
test_host
assert_default_certificate "test.example.org"
assert_sni_works
test_redirect_mode_redirects_to_configured_backend
test_frontend_url
