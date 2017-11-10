#!/bin/bash
set -eux
FIRST_SITE=$(echo $SITES | cut -f1 -d' ')

mkdir -p /etc/ssl/

render_template() {
    local template_file=$1
    local site=$2
    local server_name=$3
    local hsts_max_age=$4
    local backend_server=$5
    local default_server_label=$6
    local client_max_body_size=$7

    SERVER_NAME=$server_name \
    default_server_label=$default_server_label \
    SITE=$site \
    HSTS_MAX_AGE=$hsts_max_age \
    BACKEND_SERVER=$backend_server \
    CLIENT_MAX_BODY_SIZE=$client_max_body_size \
        envsubst '${SERVER_NAME} ${default_server_label} ${SITE} ${HSTS_MAX_AGE} ${BACKEND_SERVER} ${CLIENT_MAX_BODY_SIZE}' < $template_file
}

generate_config() {
    local site=$1
    local is_default_site=$2
    local server_name=$3
    local hsts_max_age=$4
    local backend_server=$5
    local backend_mode=$6
    local client_max_body_size=$7

    if $is_default_site; then
        default_server_label=" default_server"
    else
        default_server_label=""
    fi

    render_template /configs/http_redirect.conf "$site" "$server_name" "$hsts_max_age" "$backend_server" "$default_server_label" "$client_max_body_size"
    render_template /configs/https_proxy.conf "$site" "$server_name" "$hsts_max_age" "$backend_server" "$default_server_label" "$client_max_body_size"
}

echo "> Initializing sites $SITES"

for site in $SITES; do
    echo ">> Configuring $site"
    ssl_certificate_variable_name="${site}_SSL_CERTIFICATE"
    ssl_certificate_key_variable_name="${site}_SSL_CERTIFICATE_KEY"
    server_name_variable_name="${site}_SERVER_NAME"
    hsts_max_age_variable_name="${site}_HSTS_MAX_AGE"
    backend_server_variable_name="${site}_BACKEND_SERVER"
    backend_mode_variable_name="${site}_BACKEND_MODE"
    client_max_body_size_variable_name="${site}_CLIENT_MAX_BODY_SIZE"
    ssl_cert_file="/etc/ssl/$site.crt"
    ssl_cert_key_file="/etc/ssl/$site.key"

    echo "${!ssl_certificate_variable_name}" > $ssl_cert_file
    echo "${!ssl_certificate_key_variable_name}" > $ssl_cert_key_file
    chmod 600 $ssl_cert_key_file

    if [ "$site" == "$FIRST_SITE" ]; then
        is_default_site="true"
    else
        is_default_site="false"
    fi

    generate_config \
        "$site" \
        "$is_default_site" \
        "${!server_name_variable_name}" \
        "${!hsts_max_age_variable_name:-"600"}" \
        "${!backend_server_variable_name}" \
        "${!backend_mode_variable_name:-"proxy"}" \
        "${!client_max_body_size_variable_name:-"1m"}" > /etc/nginx/conf.d/$site.conf
    cat /etc/nginx/conf.d/$site.conf
done

set -x
nginx -g "daemon off;"
