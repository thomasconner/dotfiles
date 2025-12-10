#!/usr/bin/env bash

set -euo pipefail

echo "1Password installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if 1Password is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for 1Password in Applications
  if [[ -d "/Applications/1Password.app" ]]; then
    echo "1Password is already installed"
    exit 0
  fi
else
  if command -v 1password >/dev/null 2>&1; then
    echo "1Password is already installed"
    exit 0
  fi
fi

echo "1Password is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  # macOS: Install via Homebrew cask
  install_brew_cask 1password
  echo "1Password installed successfully"
else
  # Linux: Install via package manager
  # 1Password provides official Linux packages
  echo "For Linux installation, visit: https://1password.com/downloads/linux/"
  echo "Or use: curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg"
  exit 0
fi
