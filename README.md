# Django Container

## Features

-   Django 5.2
-   Postgres 17
-   Gunicorn 23

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
