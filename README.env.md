# Environment Variables

### `ENVIRONMENT`

-   Found in:
    -   Django `settings.py`
    -   `compose.deploy.yaml`
-   Usage:
    -   Django - If the value is `"dev"`, Django's `settings.DEBUG` will be `True`
    -   compose - Used in the name of the compose project
-   Possible values:
    -   `"dev"` - as stated above
    -   Other deployment environments like: `"local"` `"staging"` `"prod"`

### `PROJECT_NAME`

-   Found in:
    -   `compose.deploy.yaml`
    -   `compose.dev.yaml`
-   Usage:
    -   compose - Name of the project, used by docker compose to assign container names
-   Possible values:
    -   `"django-container"`
    -   Name of the project prefers dashes over underscore

### `DJANGO_SECRET_KEY`

-   Found in:
    -   Django `settings.py`
-   Usage:
    -   Django - Secret key of the Django app
-   Possible values:
    -   ASCII characters except dollar sign `$` due to parsing issues

### `DJANGO_ALLOWED_HOSTS`

-   Found in:
    -   Django `settings.py`
-   Usage:
    -   https://docs.djangoproject.com/en/5.2/ref/settings/#allowed-hosts
-   Possible values:
    -   `"localhost"`
    -   Comma-seperated list no spaces

### `GUNICORN_PORT`

-   Found in:
    -   `src/gunicorn.py`
    -   Nginx config
-   Usage:
    -   Gunicorn - Port opened to docker private network by the Django container
    -   Nginx - server:port forwarded to by the Nginx container
-   Possible values:
    -   `8080`

### `POSTGRES_DB` `POSTGRES_USER` `POSTGRES_PASSWORD`

-   Found in:
    -   Django `settings.py`
    -   `compose.deploy.yaml`
    -   `compose.dev.yaml`
-   Usage:
    -   Django - For database connections
    -   compose
        -   Used to initialize the postgres container with default values
        -   https://hub.docker.com/_/postgres#how-to-extend-this-image
-   Possible values:
    -   ASCII characters

### `SERVER_NAME`

-   Found in:
    -   Nginx config
-   Usage:
    -   https://nginx.org/en/docs/http/server_names.html
-   Possible values:
    -   ASCII characters

### `HTTP_PORT` `HTTPS_PORT`

-   Found in:
    -   Nginx config
-   Usage:
    -   Ports exposed to the host by the Nginx container
-   Possible values:
    -   `80` and `443`
