[![Build Status](https://travis-ci.org/bee-software/docker-nginx.svg?branch=master)](https://travis-ci.org/bee-software/docker-nginx)

NGINX-SNI-proxy
===============

This is an easy to configure (100% environment variable driven) reverse proxy.
It allows easy use of SNI.

Read the different examples under the test directory.

Options
=======

SITES
-----

List of sites to be configured. First site is default site (e.g. requests without Location request or no SNI support).

BACKEND_MODE
------------

Valid options: proxy (default), redirect.

- proxy: Reverse proxies to the specified backend.
- redirect: Returns a 301 redirect to the specified backend.
