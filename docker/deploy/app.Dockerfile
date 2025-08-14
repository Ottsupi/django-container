# Stage 1: Build the tailwind output
FROM node:24-slim AS tailwind_builder

WORKDIR /code

COPY package.json package.json
COPY package-lock.json package-lock.json

RUN npm ci

COPY . .

RUN npm run tailwind:build

# Stage 2: Build the app
FROM python:3.12-slim AS django_app

ENV APP_HOME="/home/app"
WORKDIR ${APP_HOME}

# Add user
RUN addgroup --system appgroup
RUN adduser --system --ingroup appgroup --home /home/app app

RUN apt update
RUN apt install -y --no-install-recommends \
    build-essential \
    libpq-dev 

RUN pip install --upgrade pip
RUN pip install --no-cache-dir psycopg[c]==3.2.*
# ^This takes a while so install it earlier for cache

COPY ./requirements/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r ./requirements.txt

COPY ./src/ .

# Copy tailwind output from Stage 1
COPY --from=tailwind_builder /code/src/assets/global.css ./assets/global.css

RUN chown -R app:appgroup ${APP_HOME}
RUN chmod +x entrypoint.sh

USER app

# The final container will only contain 
#   `requirements/` and the contents of `src/`
# Non-root user "app" will run the application 