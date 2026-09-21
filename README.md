# Django Container

## Features

-   Django 6.1
-   Tailwind 4.3
-   Postgres 18
-   Whitenoise
-   Gunicorn 26
-   Nginx
-   Dev Container

## What's been done

-   Setup TailwindCSS
-   Setup django-allauth
-   Use psycopg[c]
-   Use argon2
-   Static files served by Whitenoise
-   Media files in `src/media/` served by Django on debug mode
-   Add Django development tools:
    -   django-browser-reload
    -   django-debug-toolbar
    -   django-extensions
-   Deployment script added
-   Database backup script added

## Todo

-   Add custom user model
-   Add htmx
-   Add alpine.js
-   Setup redis
-   Setup automatic database backups
-   Setup logging to file
-   Revisit `uv` package manager
-   Add docs

## How to use in development

1. Rename directory and the dev container in `.devcontainer/devcontainer.json`
2. Manually configure your own `.env` file from `.env.sample`
3. Run `./release.dev.sh` to check and generate the required files
4. Open in VS Code using Dev Containers
    - Alternatively, run `docker compose -f compose.dev.yaml up`
      to start the development environment. Then, attach your editor
      to the `${PROJECT_NAME}-develop` container.
5. Install recommended extensions
6. Open a terminal and run these commands from `Makefile` to initialize the Django app
    ```
    make install
    make migrations
    make migrate
    make run
    ```
7. For debugging, `launch.json` is provided for VS Code's "Run and Debug"

## How to create your own deployments

1. Set all configurations from `.env`
2. Create a `compose.yaml` file to handle all services and its setup
3. Create a `release.env.sh` to handle pre-deployment checks, setup, and `git pull`

## How to do deployments

1. Configure your own `.env` file from `.env.sample`
    - Make sure `$ENVIRONMENT` is not `"dev"`
2. Follow the steps in "Setting up SSL" to generate the SSL certificate
3. Run `docker compose up` in `src/`

## Understanding the development process

-   `$ENVIRONMENT` must be `dev` during development
    -   Django's `settings.DEBUG` depends on this environment variable
-   The dev environment is defined by `compose.dev.yaml`
    -   Development is done inside the container `${PROJECT_NAME}-develop`
    -   On windows, it is recommended to have your project files inside WSL
-   There is a container running `@tailwind-cli` that watches for file changes and outputs `src/assets/global.css`
-   There is only one `settings.py`
    -   Configurations are done through environment variables
    -   `DEBUG` depends on `${ENVIRONMENT}`
-   Makefile commands are available for common dev actions

### Issues

-   Pylance does not work? Do VS Code "Reload window"
-   Packages not detected? Do VS Code "Python: Select Interpreter" and select the correct interpreter
-   Other problems? Do VS Code "Rebuild and reopen in container" (you will need to reinstall the extensions)

## Understanding the deployment process

### `compose.deploy.yaml`

-   Health checks are there to ensure that the containers are ready before performing
    the necessary operations
-   There is only one `.env` file for all containers

### Step-by-step

1. Database is built and started with the mounted docker volume `${PROJECT_NAME}-${ENVIRONMENT}_database-data`
2. Database is accessible through the address `database:5432` in the docker private network
3. Django image is built
    - Stage 1: Tailwind builds the `global.css`
    - Stage 2: Django app is built
        - Copy `requirements/requirements.txt` to `.`
        - Install the packages found in `requirements.txt`
        - Copy `src/*` to `.`
        - Copy the `global.css` into the `assets/` directory to be collected on container entrypoint
        - Final image contains only the necessary files: `requirements.txt` `src/*` `global.css`
4. Django container is started with `src/entrypoint.sh`
    - Applies database migrations
    - Collects static files
    - Starts the gunicorn server with the config `src/gunicorn.py`
5. Gunicorn is accessible through the address `server:${GUNICORN_PORT}` in the docker private network
6. Nginx container is built and started with the config `nginx/default.conf.template`
7. Nginx uses the SSL certificate and key found in `nginx/`
8. Forwards the requests to the gunicorn server
9. Exposes to the host the default ports 80 and 443 for HTTP and HTTPS respectively

### Notes:

-   Static files are served by whitenoise
-   `$ENVIRONMENT` must be NOT be `dev` on deployment
    -   Otherwise, Django's `settings.DEBUG` will be `True` and will attempt to load the dev dependencies

# Learnings

## Setting up SSL

Generally:

1. Generate certificate and key
2. Configure the web server to use them
3. Add certificate to trust stores
4. Comply with the ever-changing specs

### Generate certificate and key

0. `cd` into `./src/nginx`

1. Establish a private _Certificate Authority (CA)_

    ```sh
    openssl req -x509 -nodes \
        -newkey RSA:2048 \
        -keyout root_ca.key \
        -days 365 \
        -out root_ca.crt \
        -config root_ca.conf \
        -extensions 'v3_req'
    ```

    - Output
        - `root_ca.crt`
        - `root_ca.key`

2. Create a private key and _Certificate Signing Request (CSR)_

    ```sh
    openssl req -nodes \
        -newkey rsa:2048 \
        -keyout server.key \
        -out server.csr \
        -config server.conf \
        -extensions 'v3_req'
    ```

    - Output
        - `server.csr`
        - `server.key`

3. Generate a certificate issued by `root_ca`

    ```sh
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

    - Output
        - `server.crt`
        - `server.srl`

4. (Optional) Grant read access to the key. In some cases, docker cannot copy the file due to missing permissions
    ```sh
        chmod +r server.key
    ```

## Troubleshooting localhost SSL errors

-   If using containers, make sure port `443` is exposed
-   Learn the correct configuration for the kind of certificate you need
    -   Root CA and Server certificates need different configs
-   Make sure to add certificate to trust stores
-   Make sure to use different Distinguished Names for the `root_ca` and `server` certificates
-   Some browsers may complain about a certificate signed by a well-known certificate authority, while other browsers 
    may accept the certificate without issues. See SSL certificate chains section in the NGINX docs:
    https://nginx.org/en/docs/http/configuring_https_servers.html
-   `ERR_SSL_KEY_USAGE_INCOMPATIBLE`
    -   Server certificate `keyUsage` must have `critical, digitalSignature, keyEncipherment`
    -   https://superuser.com/a/738644
    -   https://stackoverflow.com/q/15123152
-   `SEC_ERROR_INADEQUATE_KEY_USAGE`
    -   Root CA certificate's `keyUsage` must have `critical, digitalSignature, cRLSign, keyCertSign`
-   ```
    nginx: [emerg] cannot load certificate key "/etc/ssl/private/server.key": PEM_read_bio_PrivateKey() failed 
           (SSL: error:1E08010C:DECODER routines::unsupported:No supported data to decode. Input type: PEM)
    ```
    -   In my case, the `server.key` in the NGINX container had a file size of 0 bytes. Docker failed to copy the key 
        due to insufficient permissions. Fix by adding read permissions `chmod +r server.key`

## Tips for learning NGINX

-   Study the config
-   Know where to put things
-   Learn how to point to things

## Creating Dev Containers

-   Create a user during build
-   Make sure `USER` command actually used in the Dockerfile
-   Container user's UID and GID must match that of the host user
-   Make sure to set appropriate permission levels for files and directories
    -   600 for `.bash_history`
    -   700 for `.ssh/`
    -   `chown` the container user's home directory
-   Place the project files in home subdirectory i.e. `~/code`
    -   Reminder that mounting volumes wipes the target directory in the container
    -   To prevent this, create a docker volume mount
-   SSH? No idea. SSH agent forwarding maybe, but I CANNOT get it to work x_x

## Bash scripting

-   Test expressions are awesome!!
    ```bash
    if [[ -f .env ]]; then
        echo ".env file exists!"
    fi
    ```
-   Case statements are cool too! It doesn't even highlight properly...
    ```bash
    if [[ "$KEY" =~ [\'\"\\\$] ]]; then
        echo "KEY contains the characters \\ \$ \" '"
    fi
    ```

## django-allauth

-   Make sure to configure `EMAIL_BACKEND` when encountering connection errors
-   Figure out how to customize the templates

### Installation

1. Install `django-allauth`
2. Add to `INSTALLED_APPS`
3. Configure `TEMPLATES`
4. Configure `AUTHENTICATION_BACKENDS`
5. Configure `MIDDLEWARE`
6. Configure `EMAIL_BACKEND`

# Issues encountered

-   Cannot push when inside dev containers

    -   Error:

        ```
        fatal: server certificate verification failed.
            CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
        ```

    -   Solution:

        ```
        openssl s_client \
            -showcerts -servername github.com \
            -connect github.com:443 \
            </dev/null 2>/dev/null | \
            sed -n -e \
            '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p'  > github-com.pem

        cat github-com.pem | tee -a /etc/ssl/certs/ca-certificates.crt
        ```

    -   Source: https://stackoverflow.com/a/63299750
