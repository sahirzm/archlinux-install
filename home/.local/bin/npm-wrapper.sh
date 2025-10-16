#!/bin/bash
# NPM wrapper to track globally installed packages
# Deployed via GNU Stow - add alias in your shell config: alias npm='~/.local/bin/npm-wrapper.sh'

# Path to the workspace directory
WORKSPACE_DIR="$HOME/workspace/archlinux-install"
NPM_PKGLIST="$WORKSPACE_DIR/npm-pkglist.txt"

# Run the actual npm command
command npm "$@"
NPM_EXIT_CODE=$?

# Update the package list if the command was install or uninstall with -g flag
if [[ "$*" == *"-g"* || "$*" == *"--global"* ]]; then
    if [[ "$1" == "install" || "$1" == "i" || "$1" == "uninstall" || "$1" == "remove" || "$1" == "rm" || "$1" == "un" ]]; then
        if [ -d "$WORKSPACE_DIR" ]; then
            # List all globally installed npm packages (excluding npm itself)
            command npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' | grep -v '^npm$' | sort > "$NPM_PKGLIST"
        fi
    fi
fi

exit $NPM_EXIT_CODE
