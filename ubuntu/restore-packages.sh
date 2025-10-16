#!/bin/bash
# Script to restore all tracked packages on a fresh Ubuntu installation
# Run this after setting up the repository on a new system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Package Restoration Script for Ubuntu"
echo "======================================"
echo ""

# Check if package list files exist
if [ ! -f "$WORKSPACE_DIR/ubuntu-pkglist.txt" ]; then
    echo "Error: ubuntu-pkglist.txt not found in $WORKSPACE_DIR"
    exit 1
fi

# 1. Restore APT packages
echo "Restoring APT packages..."
if [ -s "$WORKSPACE_DIR/ubuntu-pkglist.txt" ]; then
    echo "Found $(wc -l < "$WORKSPACE_DIR/ubuntu-pkglist.txt") APT packages to install"
    read -p "Do you want to install APT packages? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt update
        xargs -a "$WORKSPACE_DIR/ubuntu-pkglist.txt" sudo apt install -y
        echo "APT packages installed successfully"
    fi
else
    echo "No APT packages to restore"
fi

echo ""

# 2. Restore Cargo packages
if [ -f "$WORKSPACE_DIR/cargo-pkglist.txt" ] && [ -s "$WORKSPACE_DIR/cargo-pkglist.txt" ]; then
    echo "Restoring Cargo packages..."
    echo "Found $(wc -l < "$WORKSPACE_DIR/cargo-pkglist.txt") Cargo packages to install"

    if ! command -v cargo &> /dev/null; then
        echo "Warning: cargo is not installed. Skipping Cargo packages."
        echo "Install Rust from https://rustup.rs/ and run this script again."
    else
        read -p "Do you want to install Cargo packages? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            while IFS= read -r package; do
                echo "Installing $package..."
                cargo install "$package" || echo "Failed to install $package, continuing..."
            done < "$WORKSPACE_DIR/cargo-pkglist.txt"
            echo "Cargo packages installed"
        fi
    fi
else
    echo "No Cargo packages to restore"
fi

echo ""

# 3. Restore NPM packages
if [ -f "$WORKSPACE_DIR/npm-pkglist.txt" ] && [ -s "$WORKSPACE_DIR/npm-pkglist.txt" ]; then
    echo "Restoring NPM packages..."
    echo "Found $(wc -l < "$WORKSPACE_DIR/npm-pkglist.txt") NPM packages to install"

    if ! command -v npm &> /dev/null; then
        echo "Warning: npm is not installed. Skipping NPM packages."
        echo "Install Node.js and npm first, then run this script again."
    else
        read -p "Do you want to install NPM packages globally? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            while IFS= read -r package; do
                echo "Installing $package..."
                npm install -g "$package" || echo "Failed to install $package, continuing..."
            done < "$WORKSPACE_DIR/npm-pkglist.txt"
            echo "NPM packages installed"
        fi
    fi
else
    echo "No NPM packages to restore"
fi

echo ""
echo "======================================"
echo "Package restoration complete!"
echo ""
echo "Next steps:"
echo "1. Use GNU Stow to symlink the config files:"
echo "   cd $WORKSPACE_DIR/ubuntu"
echo "   sudo stow -t / etc      # For APT hook"
echo "   stow -t ~ home          # For wrapper scripts"
echo ""
echo "2. Add these aliases to your shell config (~/.bashrc or ~/.zshrc):"
echo "   alias cargo='~/.local/bin/cargo-wrapper.sh'"
echo "   alias npm='~/.local/bin/npm-wrapper.sh'"
echo ""
echo "3. Reload your shell: source ~/.bashrc (or source ~/.zshrc)"
