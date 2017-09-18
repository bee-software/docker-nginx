#!/bin/bash
set -eux

USE_NEXT_SITE_AS_DEFAULT=true

mkdir -p /etc/ssl/

write_default_template() {
    if $USE_NEXT_SITE_AS_DEFAULT; then
        default_server_label=" default_server"
        USE_NEXT_SITE_AS_DEFAULT=false
    else
        default_server_label=""
    fi

    # Work around templating limitations
    export DOLLAR='$'
    tee <<EOF
    server {
        listen              80$default_server_label;
        server_name         $SERVER_NAME;

        return 301 https://${DOLLAR}host${DOLLAR}request_uri;
    }

    server {
        listen              443 ssl$default_server_label;

        server_name         $SERVER_NAME;

        ssl_certificate     /etc/ssl/$SITE.crt;
        ssl_certificate_key /etc/ssl/$SITE.key;
        ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers         HIGH:!aNULL:!MD5;

        add_header          Strict-Transport-Security "max-age=$HSTS_MAX_AGE" always;

        location / {
            proxy_pass      $BACKEND_SERVER;
        }
    }
EOF
}

echo "> Initializing sites $SITES"

for site in $SITES; do
    echo ">> Configuring $site"
    ssl_certificate_variable_name="${site}_SSL_CERTIFICATE"
    ssl_certificate_key_variable_name="${site}_SSL_CERTIFICATE_KEY"
    server_name_variable_name="${site}_SERVER_NAME"
    hsts_max_age_variable_name="${site}_HSTS_MAX_AGE"
    backend_server_variable_name="${site}_BACKEND_SERVER"
    ssl_cert_file="/etc/ssl/$site.crt"
    ssl_cert_key_file="/etc/ssl/$site.key"

    echo "${!ssl_certificate_variable_name}" > $ssl_cert_file
    echo "${!ssl_certificate_key_variable_name}" > $ssl_cert_key_file
    chmod 600 $ssl_cert_key_file

    SITE=$site
    SERVER_NAME=${!server_name_variable_name}
    HSTS_MAX_AGE=${!hsts_max_age_variable_name:-"600"}
    BACKEND_SERVER=${!backend_server_variable_name}
    write_default_template > /etc/nginx/conf.d/$site.conf
done

set -x
nginx -g "daemon off;"