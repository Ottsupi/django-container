FROM nginx

WORKDIR /etc/nginx/templates

COPY default.conf.template /etc/nginx/templates/default.conf.template

COPY localhost.crt /etc/ssl/private/localhost.crt

COPY localhost.key /etc/ssl/private/localhost.key
