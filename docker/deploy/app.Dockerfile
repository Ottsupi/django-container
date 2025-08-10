# Stage 1: Build the tailwind output
FROM node:24-slim AS tailwind_builder

WORKDIR /code

COPY package.json package.json
COPY package-lock.json package-lock.json

RUN npm install

COPY . .

RUN npm run tailwind:build

# Stage 2: Build the app
FROM python:3.12 AS django_app

RUN apt update && apt upgrade -y
RUN apt install -y libpq-dev python3-dev

RUN pip install --upgrade pip

ENV APP_HOME="/code"
WORKDIR ${APP_HOME}

# This takes a while so install it earlier for cache
RUN pip install --no-cache-dir psycopg[c]==3.2.*

COPY ./requirements/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r ./requirements.txt

COPY ./src/ .

# Copy tailwind output from Stage 1
COPY --from=tailwind_builder /code/src/assets/global.css ./assets/global.css

RUN ["chmod", "+x", "entrypoint.sh"]

# The final container will only contain 
# `requirements/` and the contents of `src/`