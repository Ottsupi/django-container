#!/bin/bash

LOGFILE="logs/releases.log"
exec > >(tee -a "$LOGFILE") 2>&1

DATE=$(date -u +%Y-%m-%dT%H-%M-%SZ)
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


# Help text
function help() {
    echo "This is the deployment script for..."
    echo "Project:     $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "Directory:   $BASE_PATH"
    echo "Branch:      $(git rev-parse --abbrev-ref HEAD)"
    echo ""
    echo "Usage:"
    echo "./$(basename $0) [options]"
    echo ""
    echo "Options:"
    echo "--deploy            Must be set to actually rebuild and rerun the containers"
    echo "--initial           Specifies initial deployment"
    echo "--no-code-change    Allows the script to run even without code changes."
    echo "--no-db-backup      Disable pre code change database backup."
    echo "--no-porcelain      Disable clean git worktree check"
    echo ""
    echo "Recommended: Run with 'tee' to create log file"
    echo "             ./$(basename $0) 2>&1 | tee -a logs/releases.log"
    exit 0
}

echo ""
echo "==============$DATE=============="
echo ""

# Handle flags

FLAG_DEPLOY=0
FLAG_INITIAL=0
FLAG_NO_CODE_CHANGE=0
FLAG_NO_DB_BACKUP=0
FLAG_NO_PORCELAIN=0

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h | --help)
            help
            ;;
        --deploy)
            echo "Deployment enabled"
            FLAG_DEPLOY=1
            ;;
        --initial)
            echo "Initial deployment"
            FLAG_INITIAL=1
            FLAG_NO_CODE_CHANGE=1
            FLAG_NO_DB_BACKUP=1
            ;;
        --no-code-change)
            echo "Deploy without code change"
            FLAG_NO_CODE_CHANGE=1
            ;;
        --no-db-backup)
            echo "Database backup disabled"
            FLAG_NO_DB_BACKUP=1
            ;;
        --no-porcelain)
            echo "Disable clean git worktree check"
            FLAG_NO_PORCELAIN=1
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done


# This part is simply a "static" check to make sure
# there is nothing amiss in the .env file

echo ""
echo "*** Pre-release Script ***"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Directory:   $BASE_PATH"
echo "Date:        $DATE"

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


# Setup SSL for localhost

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
    if [ $? -eq 1 ]; then
        echo "Error creating root ca"
        exit 1
    fi
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
    if [ $? -eq 1 ]; then
        echo "Error creating server csr"
        exit 1
    fi
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
    if [ $? -eq 1 ]; then
        echo "Error creating server certificate"
        exit 1
    fi
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

echo ""
echo "Attempting to backup database before applying code changes..."

if [ $FLAG_NO_DB_BACKUP -eq 1 ]; then
    echo "Database backup disabled."
    echo "Skipping database backup..."
else
    # Backup database, exit if failed 
    ./scripts/local.db-backup.sh
    if [ $? -eq 1 ]; then
        echo "Database backup failed!"
        exit 1
    fi
fi

echo ""
echo "Attempting to update git repository..."
echo ""


echo "*** Git Repository Script ***"
# Check if git worktree is clean
if [ $FLAG_NO_PORCELAIN -eq 0 ]; then
    if [[ $(git status --porcelain) ]]; then
        echo "Git worktree is dirty"
        echo "Uncommitted changes found:"
        git status --porcelain
        echo "NOT RECOMMENDED: Use flag '--no-porcelain' to allow deploying dirty working tree"
        echo "Reminder: 'git fetch' and 'git pull' is called after this which may cause"
        echo "           merge conficts, so it is recommended to clean the working tree first"
        exit 1
    fi
fi

git fetch
if [ $? -eq 1 ]; then
    echo "'git fetch' failed"
    echo "!!! Git Repository Script Failed !!!"
    exit 1
fi

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PRE_FETCH_HEAD_COMMIT_HASH=$(git rev-parse --short HEAD)
FETCH_HEAD_COMMIT_HASH=$(git rev-parse --short FETCH_HEAD)
POST_MERGE_HEAD_COMMIT_HASH=""
echo "Branch:     $GIT_BRANCH"
echo "HEAD:       $PRE_FETCH_HEAD_COMMIT_HASH"
echo "FETCH_HEAD: $FETCH_HEAD_COMMIT_HASH"
echo ""

# Print only the first two lines from 'git status'
echo "Git Status Report (pre-merge):"
git status | head -n 2
echo ""

echo "Git Fetch Report:"
NEW_COMMITS_COUNT= git --no-pager log --decorate=short --oneline ..FETCH_HEAD | wc -l | tr -d '\n'
echo "$NEW_COMMITS_COUNT new commits from remote"
if [[ $NEW_COMMITS_COUNT -gt 0 ]]; then
    git --no-pager log --decorate=short --oneline ..FETCH_HEAD | wc -l
fi
echo ""

# If the --deploy flag is not set, cut the script right here
if [ $FLAG_DEPLOY -eq 0 ]; then
    echo "Code changes fetched but not yet merged"
    echo "Script will not continue to deployment"
    echo "Use '--deploy' flag to continue"
    exit 0
fi

echo "Merging..."
git merge
if [ $? -eq 1 ]; then
    echo "'git merge' failed"
    echo "!!! Git Repository Script Failed !!!"
    exit 1
fi
POST_MERGE_HEAD_COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""

echo "Git Status Report (post-merge):"
git status | head -n 2
echo ""

# If there are NO new changes and flag --no_code_change is not set, exit
if [[ $NEW_COMMITS_COUNT -gt 0 ]]; then
    echo "$PRE_FETCH_HEAD_COMMIT_HASH -> $POST_MERGE_HEAD_COMMIT_HASH"
    echo "Code changes applied!"
else
    echo "$PRE_FETCH_HEAD_COMMIT_HASH -> $POST_MERGE_HEAD_COMMIT_HASH"
    echo "No code changes"
    if [ $FLAG_NO_CODE_CHANGE -eq 1 ]; then
        echo "Allowed to deploy"
    else
        echo "Deployment NOT allowed"
        echo "Use flag '--no-code-changes' to allow deployments without new changes"
        exit 0
    fi
fi
echo "*** Git Repository Script Finished ***"

echo ""
echo "Attempting to deploy..."
echo ""

echo "*** Release Script ***"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Directory:   $BASE_PATH"
echo "Branch:      $GIT_BRANCH"
echo "Commit ID:   $POST_MERGE_HEAD_COMMIT_HASH"

echo ""
echo "Ready for deployment!"
echo "Docker will take it from here."
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
