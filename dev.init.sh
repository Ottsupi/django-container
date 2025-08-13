#!/bin/bash

BASE_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ENV_FILE="$BASE_PATH/.env"
BASH_HISTORY_FILE="$BASE_PATH/.devcontainer/.bash_history"
BASH_HISTORY_TEMPLATE="$BASE_PATH/.devcontainer/bash_history.template"
BASHRC_FILE="$BASE_PATH/.devcontainer/.bashrc"
BASHRC_TEMPLATE="$BASE_PATH/.devcontainer/bashrc.template.sh"

CURRENT_STEP=0
TOTAL_STEPS=3


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

echo ""
echo "Setup successful!"
echo "For VS Code and Dev Containers extension."
echo "Ctrl + Shift + P > 'Rebuild and Reopen in Container'"
echo ""
