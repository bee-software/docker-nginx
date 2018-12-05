[![Build Status](https://travis-ci.org/bee-software/docker-nginx.svg?branch=master)](https://travis-ci.org/bee-software/docker-nginx)

NGINX
=====

This is an easy to configure (100% environment variable driven) reverse proxy.
It allows easy use of SNI.

This image was created because all other NGINX images at the time only supported
passing configuration files via volume mounting, or creating derivative images.

This image provides SSL termination as a utility which can be plugged into any existing stack.


Typical usage
=============

Declare a new service to handle SSL termination for your services, as such:

    version: '3'
    
    services:
      wordpress:
        image: wordpress
      
      other-app:
        image: tomcat
        
      proxy:
        image: beesoftware/nginx:latest
        environment:
          SITES: "WORDPRESS MY_OTHER_APP"

          WORDPRESS_SERVER_NAME: "test.example.org"
          WORDPRESS_BACKEND_SERVER: "http://wordpress/"
          WORDPRESS_SSL_CERTIFICATE: |-
            -----BEGIN CERTIFICATE-----
            <snip>
            -----END CERTIFICATE-----
          WORDPRESS_SSL_CERTIFICATE_KEY: |-
            -----BEGIN RSA PRIVATE KEY-----
            <snip>
            -----END RSA PRIVATE KEY-----

          MY_OTHER_APP_SERVER_NAME: "test.example.org"
          MY_OTHER_APP_BACKEND_SERVER: "http://other-app/"
          MY_OTHER_APP_SSL_CERTIFICATE: |-
            -----BEGIN CERTIFICATE-----
            <snip>
            -----END CERTIFICATE-----
          MY_OTHER_APP_SSL_CERTIFICATE_KEY: |-
            -----BEGIN RSA PRIVATE KEY-----
            <snip>
            -----END RSA PRIVATE KEY-----

Options
=======

SITES
-----

List of sites to be configured. First site is default site (e.g. requests without Location request or no SNI support).


SERVER_NAME
-----------

Domain name to use for the server name nginx directive.


BACKEND_SERVER
--------------

Complete URL for the backend server for this site.


BACKEND_MODE
------------

Valid options: proxy (default), redirect.

- proxy: Reverse proxies to the specified backend.
- redirect: Returns a 301 redirect to the specified backend.


READ_TIMEOUT
------------

Configures read timeout.


HSTS_MAX_AGE
------------

HSTS is configured out of the box for improved security.
The Max-Age directive can be configured using the HSTS_MAX_AGE environment variable.


FRONTEND_URL
------------

You can specify a different frontend URL using this parameter.

A different frontend URL allows map a URL to a different backend URL, for example:

https://example.com/bingo/ -> http://backend/


BASIC_AUTH
----------

HTTP basic authentication can be configured by using this parameter.

Multiple values can be provided, as such:
    
    TEST_BASIC_AUTH: |-
        username:$$apr1$$Mgq8bs09$$93K0.B7zL30ERLPoIa8zH1
        anotherUser:$$apr1$$Mgq8bs09$$93K0.B7zL30ERLPoIa8zH1
        
Dollar signs have to be doubled inside of docker-compose files.