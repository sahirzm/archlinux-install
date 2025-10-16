#!/bin/bash
# Cargo wrapper to track globally installed packages
# Deployed via GNU Stow - add alias in your shell config: alias cargo='~/.local/bin/cargo-wrapper.sh'

# Path to the workspace directory
WORKSPACE_DIR="$HOME/workspace/archlinux-install"
CARGO_PKGLIST="$WORKSPACE_DIR/cargo-pkglist.txt"

# Run the actual cargo command
command cargo "$@"
CARGO_EXIT_CODE=$?

# Update the package list if the command was install or uninstall
if [[ "$1" == "install" || "$1" == "uninstall" ]]; then
    if [ -d "$WORKSPACE_DIR" ]; then
        # List all installed cargo binaries
        command cargo install --list | grep -E '^[a-zA-Z0-9_-]+ v[0-9]' | awk '{print $1}' | sort > "$CARGO_PKGLIST"
    fi
fi

exit $CARGO_EXIT_CODE
