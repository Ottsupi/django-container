#!/bin/bash

SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_PATH=$( dirname $SCRIPT_PATH )
ENV_FILE=$BASE_PATH/.env

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

CONTAINER_NAME="$PROJECT_NAME-$ENVIRONMENT-database-1"
if [ $(docker ps -a | grep -c "$CONTAINER_NAME") -eq 0 ]; then
    echo "ERROR: Container $CONTAINER_NAME does not exist"
    exit 1
fi

CONTAINER_IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")
if [ "$CONTAINER_IS_RUNNING" == "false" ]; then
    echo "ERROR: Container $CONTAINER_NAME is not running"
    exit 1
fi

echo "*** Database Backup Script ***"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Directory:   $BASE_PATH"
echo "Container:   $CONTAINER_NAME"
echo "Creating backup..."

DATE=$(date -u +%Y-%m-%dT%H-%M-%SZ)
GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
BACKUP_FILE=database/$PROJECT_NAME-$ENVIRONMENT-$DATE-$GIT_COMMIT_HASH.sql

PGPASSWORD=$POSTGRES_PASSWORD
docker exec c-user-local-database-1 pg_dump \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB \
    > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "Created backup $BACKUP_FILE"
    echo "*** Database Backup Script Finished ***"
    exit 0
else
    echo "Failed to create backup"
    echo "!!! Database Backup Script Failed !!!"
    exit 1
fi

