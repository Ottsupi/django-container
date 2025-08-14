#!/bin/bash

BASE_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ENV_FILE="$BASE_PATH/.env"

# Export .env to shell
if [ -f $ENV_FILE ]; then
    set -a
    source .env
    set +a
else
    echo ""
    echo "ERROR: .env file not found"
    echo "Please setup your own .env from the template .env.sample"
    echo ""
    return 1
fi

echo ""
echo "Release script for dev environment"
echo ""
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Directory:   $BASE_PATH"
echo ""

BASH_HISTORY_FILE="$BASE_PATH/.devcontainer/.bash_history"
BASH_HISTORY_TEMPLATE="$BASE_PATH/.devcontainer/bash_history.template"
BASHRC_FILE="$BASE_PATH/.devcontainer/.bashrc"
BASHRC_TEMPLATE="$BASE_PATH/.devcontainer/bashrc.template.sh"

TOTAL_STEPS=2
CURRENT_STEP=0
SOLUTIONS=()

((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Checking .env file..."
if [[ "$ENVIRONMENT" == "dev" ]]; then
    echo "  ✓  ENVIRONMENT is dev"
else
    echo "  ✗  ENVIRONMENT is NOT dev"
    SOLUTIONS+=("Make sure ENVIRONMENT is exactly \"dev\"")
fi

if [[ "$DEV_CONTAINER_UID" == "$(id -u)" ]]; then
    echo "  ✓  DEV_CONTAINER_UID matches current user id"
else
    echo "  ✗  DEV_CONTAINER_UID does NOT match current user id"
    SOLUTIONS+=("Get user id with the command 'id -u'")
fi

if [[ "$DEV_CONTAINER_GID" == "$(id -g)" ]]; then
    echo "  ✓  DEV_CONTAINER_GID matches current user's group id"
else
    echo "  ✗  DEV_CONTAINER_UID does NOT match current user's group id"
    SOLUTIONS+=("Get user id with the command 'id -g'")
fi


((CURRENT_STEP++))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Checking bash files..."
if [ -f $BASH_HISTORY_FILE ]; then
    echo "  ✓  .bash_history found"
else
    cp $BASH_HISTORY_TEMPLATE $BASH_HISTORY_FILE
    echo "  ✓  created empty .bash_history"
fi

if [ -f $BASHRC_FILE ]; then
    echo "  ✓  .bashrc found"
else
    cp $BASHRC_TEMPLATE $BASHRC_FILE
    echo "  ✓  created .bashrc from template"
fi

if [[ "${#SOLUTIONS[@]}" -gt 0 ]]; then
    echo ""
    echo "Solutions:"
    for solution in "${SOLUTIONS[@]}"; do
        echo " - $solution"
    done
    echo ""
    echo "Some problems occured. Please fix to continue"
    echo ""
    return 0
fi

echo ""
echo "Ready for development!"
echo "This project is meant for VS Code with Dev Containers extension"
echo "    Ctrl + Shift + P > 'Reopen in container'"
echo ""
