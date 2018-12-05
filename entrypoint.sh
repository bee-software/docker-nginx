#!/bin/bash
set -eux
FIRST_SITE=$(echo $SITES | cut -f1 -d' ')

mkdir -p /etc/ssl/

render_template() {
    local template_file=$1; shift
    local site=$1; shift
    local server_name=$1; shift
    local hsts_max_age=$1; shift
    local frontend_url=$1; shift
    local backend_server=$1; shift
    local default_server_label=$1; shift
    local client_max_body_size=$1; shift
    local redirect_destination=$1; shift
    local read_timeout=$1; shift
    local auth_basic=$1; shift

    SERVER_NAME=$server_name \
    default_server_label=$default_server_label \
    SITE=$site \
    HSTS_MAX_AGE=$hsts_max_age \
    FRONTEND_URL=$frontend_url \
    BACKEND_SERVER=$backend_server \
    CLIENT_MAX_BODY_SIZE=$client_max_body_size \
    REDIRECT_DESTINATION=$redirect_destination \
    READ_TIMEOUT=$read_timeout \
    AUTH_BASIC=${auth_basic:-"off"} \
        envsubst '${SERVER_NAME} ${default_server_label} ${SITE} ${HSTS_MAX_AGE} ${FRONTEND_URL} ${BACKEND_SERVER} ${CLIENT_MAX_BODY_SIZE} ${REDIRECT_DESTINATION} ${READ_TIMEOUT} ${AUTH_BASIC}' < $template_file
}

generate_config() {
    local site=$1; shift
    local is_default_site=$1; shift
    local server_name=$1; shift
    local hsts_max_age=$1; shift
    local frontend_url=$1; shift
    local backend_server=$1; shift
    local backend_mode=$1; shift
    local client_max_body_size=$1; shift
    local read_timeout=$1; shift
    local auth_basic=$1; shift

    if $is_default_site; then
        default_server_label=" default_server"
    else
        default_server_label=""
    fi

    if [ "$backend_mode" == "proxy" ]; then
        render_template /configs/http_redirect.conf \
            "$site" \
            "$server_name" \
            "$hsts_max_age" \
            "$frontend_url" \
            "$backend_server" \
            "$default_server_label" \
            "$client_max_body_size" \
            "https://\$host\$request_uri" \
            "$read_timeout" \
            "$auth_basic"

        render_template /configs/https_proxy.conf \
            "$site" \
            "$server_name" \
            "$hsts_max_age" \
            "$frontend_url" \
            "$backend_server" \
            "$default_server_label" \
            "$client_max_body_size" \
            "" \
            "$read_timeout" \
            "$auth_basic"

    elif [ "$backend_mode" == "redirect" ]; then
        render_template /configs/http_redirect.conf \
            "$site" \
            "$server_name" \
            "$hsts_max_age" \
            "$frontend_url" \
            "$backend_server" \
            "$default_server_label" \
            "$client_max_body_size" \
            "${backend_server%/}\$request_uri" \
            "$read_timeout" \
            "$auth_basic"
        
        render_template /configs/https_redirect.conf \
            "$site" \
            "$server_name" \
            "$hsts_max_age" \
            "$frontend_url" \
            "$backend_server" \
            "$default_server_label" \
            "$client_max_body_size" \
            "${backend_server%/}\$request_uri" \
            "$read_timeout" \
            "$auth_basic"
            
    else
        echo "Unsupported backend mode $backend_mode for site $site."
        exit 1
    fi
}

echo "> Initializing sites $SITES"

for site in $SITES; do
    echo ">> Configuring $site"
    ssl_certificate_variable_name="${site}_SSL_CERTIFICATE"
    ssl_certificate_key_variable_name="${site}_SSL_CERTIFICATE_KEY"
    server_name_variable_name="${site}_SERVER_NAME"
    hsts_max_age_variable_name="${site}_HSTS_MAX_AGE"
    frontend_url_variable_name="${site}_FRONTEND_URL"
    backend_server_variable_name="${site}_BACKEND_SERVER"
    backend_mode_variable_name="${site}_BACKEND_MODE"
    client_max_body_size_variable_name="${site}_CLIENT_MAX_BODY_SIZE"
    read_timeout_variable_name="${site}_READ_TIMEOUT"
    basic_auth_variable_name="${site}_BASIC_AUTH"
    ssl_cert_file="/etc/ssl/$site.crt"
    ssl_cert_key_file="/etc/ssl/$site.key"

    echo "${!ssl_certificate_variable_name}" > $ssl_cert_file
    echo "${!ssl_certificate_key_variable_name}" > $ssl_cert_key_file
    chmod 600 $ssl_cert_key_file

    echo "${!basic_auth_variable_name:-""}" > /etc/nginx/${site}.htpasswd

    if [ -n "${!basic_auth_variable_name:-""}" ]; then
        auth_basic="Restricted"
    else
        auth_basic="off"
    fi

    if [ "$site" == "$FIRST_SITE" ]; then
        is_default_site="true"
    else
        is_default_site="false"
    fi

    generate_config \
        "$site" \
        "$is_default_site" \
        "${!server_name_variable_name}" \
        "${!hsts_max_age_variable_name:-"63072000"}" \
        "${!frontend_url_variable_name:-"/"}" \
        "${!backend_server_variable_name}" \
        "${!backend_mode_variable_name:-"proxy"}" \
        "${!client_max_body_size_variable_name:-"1m"}" \
        "${!read_timeout_variable_name:-"120s"}" \
        "${auth_basic}" > /etc/nginx/conf.d/$site.conf
    cat /etc/nginx/conf.d/$site.conf
done

set -x
nginx -g "daemon off;"
