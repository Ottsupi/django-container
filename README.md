# Django Container

## Features

* Django 5.2
* Postgres 17
* Gunicorn 23
* Nginx

## What's been done

* Use psycopg-c
* Use argon2
* Static files served by NGINX
* Add Django development tools:
  * django-debug-toolbar
  * django-extensions
  * Note: only when settings.DEBUG is true
* Docker compose in the root directory for development
    using VS Code dev container
* Docker compose in `src` directory for deployment
  * Gunicorn as app server
  * NGINX as reverse proxy
  * HTTPS enabled for local deployment

## How to use in development

1. Rename the `.env.sample` file to `.env` found in `src/`
2. Open in VS Code using Dev Containers
3. Install recommended extensions
4. Start development
* In case pylance does not work, do VS Code "reload window"
    after installing the Python extensions

## How to deploy locally with SSL
1. Rename the `.env.sample` file to `.env` found in `src/`
2. Follow the steps below to generate the SSL certificate
3. Run `docker compose up` in `src/`

## Folder structure

* Everything needed for the app to be deployed is found inside `src/`
* Everything else outside that is needed for development


# Learnings

## Setting up SSL

1. Genarate certificate and key
2. Configure the web server to use them
3. Add certificate to trust stores
4. Comply with the ever-changing specs

## Generate certificate and key

0. `cd` into `./src/nginx`

1. Establish a private _Certificate Authority (CA)_
    ```sh-session
    openssl req -x509 -nodes \
        -newkey RSA:2048 \
        -keyout root_ca.key \
        -days 365 \
        -out root_ca.crt \
        -config root_ca.conf \
        -extensions 'v3_req'
    ```
    * Output
        * `root_ca.crt`
        * `root_ca.key`

2. Create a private key and _Certificate Signing Request (CSR)_
    ```sh-session
    openssl req -nodes \
        -newkey rsa:2048 \
        -keyout server.key \
        -out server.csr \
        -config server.conf \
        -extensions 'v3_req'
    ```
    * Output
        * `server.csr`
        * `server.key`

3. Generate a certificate issued by `root_ca`
    ```sh-session
    openssl x509 -req \
        -CA root_ca.crt \
        -CAkey root_ca.key \
        -in server.csr \
        -out server.crt \
        -days 365 \
        -extfile server.conf \
        -extensions 'v3_req' \
        -CAcreateserial
    ```
    * Output
        * `server.crt`
        * `server.srl`

## Troubleshooting localhost SSL errors

-   If using containers, make sure port `443` is exposed
-   Make sure to add certificate to trust stores
-   Make sure to use different Distinguished Names for the `root_ca` and `server` certificates
-   Some browsers may complain about a certificate signed by a well-known certificate authority, while other browsers may accept the certificate without issues. See SSL certificate chains section in the NGINX docs: https://nginx.org/en/docs/http/configuring_https_servers.html
-   `ERR_SSL_KEY_USAGE_INCOMPATIBLE`
    -   `keyUsage` must have `critical, digitalSignature, keyEncipherment`
    -   https://superuser.com/a/738644
    -   https://stackoverflow.com/q/15123152
-   `SEC_ERROR_INADEQUATE_KEY_USAGE`
    -   `keyUsage` must have `critical, digitalSignature, cRLSign, keyCertSign`

## Tips for learning NGINX

-   Study the config
-   Know where to put things
-   Learn how to point to things
