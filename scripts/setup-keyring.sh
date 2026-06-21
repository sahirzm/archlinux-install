#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================="
echo "   Sway + Wayland Keyring Auto-Setup     "
echo "========================================="

# 1. Install required system packages
echo "--> Installing necessary packages..."
sudo pacman -S --needed --noconfirm gnome-keyring libsecret pinentry

# 2. Configure terminal-only password entry fallback
echo "--> Configuring pinentry for TTY fallback..."
mkdir -p "$HOME/.gnupg"
if ! grep -q "pinentry-program" "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null; then
  echo "pinentry-program /usr/bin/pinentry-tty" >>"$HOME/.gnupg/gpg-agent.conf"
fi
gpgconf --kill gpg-agent

# 3. Prompt user safely for their Linux login password
echo ""
echo "Please enter your Arch Linux user password."
echo "This is required to securely encrypt the login keyring file so it matches your TTY login."
read -rs -p "Password: " USER_PASS
echo ""

if [ -z "$USER_PASS" ]; then
  echo "Error: Password cannot be blank for Option 2 setup."
  exit 1
fi

# 4. Clean up any stale or corrupted keyrings
echo "--> Initializing clean keyring database..."
killall gnome-keyring-daemon 2>/dev/null || true
rm -rf "$HOME/.local/share/keyrings"/*
mkdir -p "$HOME/.local/share/keyrings"

# 5. Set default keyring target
echo "login" >"$HOME/.local/share/keyrings/default"

# 6. Initialize the login keyring database silently using standard input
echo -n "$USER_PASS" | gnome-keyring-daemon --login

# 7. Configure PAM stack for automatic unlocking on TTY login
echo "--> Injecting hooks into /etc/pam.d/login..."
sudo sed -i '/pam_gnome_keyring/d' /etc/pam.d/login
sudo bash -c 'echo "auth       optional     pam_gnome_keyring.so" >> /etc/pam.d/login'
sudo bash -c 'echo "session    optional     pam_gnome_keyring.so auto_start" >> /etc/pam.d/login'

echo "========================================="
echo " Setup complete! Please restart your PC. "
echo "========================================="
