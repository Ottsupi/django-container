FROM nginx

WORKDIR /etc/nginx/templates

COPY default.conf.template /etc/nginx/templates/default.conf.template

COPY server.crt /etc/ssl/certs/server.crt

COPY server.key /etc/ssl/private/server.key
