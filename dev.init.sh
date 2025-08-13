#!/bin/bash

BASE_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
NGINX_PATH="$BASE_PATH/nginx"

ENV_FILE="$BASE_PATH/.env"
BASH_HISTORY_FILE="$BASE_PATH/.devcontainer/.bash_history"
BASH_HISTORY_TEMPLATE="$BASE_PATH/.devcontainer/bash_history.template"
BASHRC_FILE="$BASE_PATH/.devcontainer/.bashrc"
BASHRC_TEMPLATE="$BASE_PATH/.devcontainer/bashrc.template.sh"

ROOT_CA_CONF_FILE="$NGINX_PATH/root_ca.conf"
ROOT_CA_CRT_FILE="$NGINX_PATH/root_ca.crt"
ROOT_CA_KEY_FILE="$NGINX_PATH/root_ca.key"
SERVER_CONF_FILE="$NGINX_PATH/server.conf"
SERVER_CSR_FILE="$NGINX_PATH/server.csr"
SERVER_CRT_FILE="$NGINX_PATH/server.crt"
SERVER_KEY_FILE="$NGINX_PATH/server.key"

CURRENT_STEP=0
TOTAL_STEPS=4


echo ""
echo "Initializing developer environment at:"
echo "    $BASE_PATH"
echo ""


((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Checking .env file..."
if [ -f $ENV_FILE ]; then
    echo "  ✓ .env found"
else
    echo "  E file not found"
    echo "  E Please setup your .env file first"
    echo ""
    return 1
fi


((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Checking .bash_history file..."
if [ -f $BASH_HISTORY_FILE ]; then
    echo "  ✓ .bash_history found"
else
    cp $BASH_HISTORY_TEMPLATE $BASH_HISTORY_FILE
    echo "  ✓ created empty .bash_history"
fi


((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Checking .bashrc file..."
if [ -f $BASHRC_FILE ]; then
    echo "  ✓ .bashrc found"
else
    cp $BASHRC_TEMPLATE $BASHRC_FILE
    echo "  ✓ created .bashrc from template"
fi


((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Setting up HTTPS for local deployment..."
if [[ -f $ROOT_CA_CRT_FILE && -f $ROOT_CA_KEY_FILE ]]; then
    echo "  ✓ root ca found"
else
    openssl req -x509 -noenc -quiet \
        -newkey RSA:2048 \
        -keyout $ROOT_CA_KEY_FILE \
        -days 365 \
        -out nginx/root_ca.crt \
        -config nginx/root_ca.conf \
        -extensions 'v3_req' \
        &>/dev/null
    echo "  ✓ created root ca"
fi

if [[ -f $SERVER_CSR_FILE && -f $SERVER_KEY_FILE ]]; then
    echo "  ✓ server key and csr found"
else
    openssl req -noenc -quiet \
        -newkey rsa:2048 \
        -keyout $SERVER_KEY_FILE \
        -out $SERVER_CSR_FILE \
        -config $SERVER_CONF_FILE \
        -extensions 'v3_req' \
        &>/dev/null
    echo "  ✓ created server csr"
fi

if [ -f $SERVER_CRT_FILE ]; then
    echo "  ✓ server certificate found"
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
    echo "  ✓ created server certificate"
fi


echo ""
echo "Setup successful!"
echo "For VS Code and Dev Containers extension."
echo "Ctrl + Shift + P > 'Rebuild and Reopen in Container'"
echo ""
