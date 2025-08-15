#!/bin/bash

BASE_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ENV_FILE="$BASE_PATH/.env"

# Export .env to shell
if [ -f $ENV_FILE ]; then
    set -a
    source .env
    set +a
else
    echo "ERROR: .env file not found"
    echo "Please setup your own .env from the template .env.sample"
    exit 1
fi

echo "*** Pre-release Script ***"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Directory:   $BASE_PATH"

TOTAL_STEPS=2
CURRENT_STEP=0
SOLUTIONS=()

((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Checking .env file..."
if [[ "$ENVIRONMENT" == "local" ]]; then
    echo "  ✓  ENVIRONMENT is local"
else
    echo "  ✗  ENVIRONMENT is NOT local"
    SOLUTIONS+=("Make sure ENVIRONMENT is exactly \"local\"")
fi

if [[ "$DJANGO_SECRET_KEY" == "generate-your-own-key" ]]; then
    echo "  ✗  DJANGO_SECRET_KEY is NOT secure"
    SOLUTIONS+=("Please generate your own secret key")
elif [[ "$DJANGO_SECRET_KEY" =~ [\'\"\\\$] ]]; then
    echo "  ✗  DJANGO_SECRET_KEY contains: \\ \$ \" '"
    SOLUTIONS+=("Please avoid these characters in the secret key: \\ \$ \" '")
else
    echo "  ✓  DJANGO_SECRET_KEY is valid"
fi


NGINX_PATH="$BASE_PATH/nginx"
ROOT_CA_CONF_FILE="$NGINX_PATH/root_ca.conf"
ROOT_CA_CRT_FILE="$NGINX_PATH/root_ca.crt"
ROOT_CA_KEY_FILE="$NGINX_PATH/root_ca.key"
SERVER_CONF_FILE="$NGINX_PATH/server.conf"
SERVER_CSR_FILE="$NGINX_PATH/server.csr"
SERVER_CRT_FILE="$NGINX_PATH/server.crt"
SERVER_KEY_FILE="$NGINX_PATH/server.key"

((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Setting up HTTPS for local deployment..."
if [[ -f $ROOT_CA_CRT_FILE && -f $ROOT_CA_KEY_FILE ]]; then
    echo "  ✓  root ca found"
else
    openssl req -x509 -noenc \
        -newkey RSA:2048 \
        -keyout $ROOT_CA_KEY_FILE \
        -days 365 \
        -out $ROOT_CA_CRT_FILE \
        -config $ROOT_CA_CONF_FILE \
        -extensions 'v3_req' \
        &>/dev/null
    echo "  ✓  created root ca"
fi

if [[ -f $SERVER_CSR_FILE && -f $SERVER_KEY_FILE ]]; then
    echo "  ✓  server key and csr found"
else
    openssl req -noenc \
        -newkey rsa:2048 \
        -keyout $SERVER_KEY_FILE \
        -out $SERVER_CSR_FILE \
        -config $SERVER_CONF_FILE \
        -extensions 'v3_req' \
        &>/dev/null
    echo "  ✓  created server csr"
fi

if [ -f $SERVER_CRT_FILE ]; then
    echo "  ✓  server certificate found"
else
    openssl x509 -req \
        -CA $ROOT_CA_CRT_FILE \
        -CAkey $ROOT_CA_KEY_FILE \
        -in $SERVER_CSR_FILE \
        -out $SERVER_CRT_FILE \
        -days 365 \
        -extfile $SERVER_CONF_FILE \
        -extensions 'v3_req' \
        &>/dev/null
    echo "  ✓  created server certificate"
fi

if [[ "${#SOLUTIONS[@]}" -gt 0 ]]; then
    echo "Solutions:"
    for solution in "${SOLUTIONS[@]}"; do
        echo " - $solution"
    done
    echo "Some problems occured. Please fix to continue."
    exit 1
fi

echo "*** Pre-release Script Finished ***"

# Do database backup if possible
# If not, just ignore
echo ""
echo "Attempting to backup database..."
echo ""

./scripts/local.db-backup.sh

if [ $? -eq 1 ]; then
    echo "Skipping pre-deploy database backup..."
fi


echo ""
echo "Attempting to update git repository..."
echo ""

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
OLD_GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
git pull
LATEST_GIT_COMMIT_HASH=$(git rev-parse --short HEAD)

if [ "$OLD_GIT_COMMIT_HASH" == "$LATEST_GIT_COMMIT_HASH" ]; then
    echo "Branch:  $GIT_BRANCH"
    echo "Latest:  $LATEST_GIT_COMMIT_HASH"
    echo "Current: $OLD_GIT_COMMIT_HASH"
    echo "No new changes to deploy"
    exit 0
fi

echo "*** Release Script ***"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Directory:   $BASE_PATH"
echo "Branch:      $GIT_BRANCH"
echo "Commit ID:   $LATEST_GIT_COMMIT_HASH"

echo "Ready for deployment to local!"
echo "Starting in..."
sleep 1

COUNTDOWN=5
while [ $COUNTDOWN -gt 0 ]; do
  echo "$COUNTDOWN"
  ((--COUNTDOWN))
  sleep 2
done

docker compose -f compose.local.yaml up --build --no-deps --force-recreate -d
# docker compose -f compose.local.yaml up -d
