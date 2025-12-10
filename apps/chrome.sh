#!/usr/bin/env bash

set -euo pipefail

echo "Google Chrome installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if Chrome is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for Chrome in Applications
  if [[ -d "/Applications/Google Chrome.app" ]]; then
    echo "Google Chrome is already installed"
    exit 0
  fi
else
  if command -v google-chrome >/dev/null 2>&1; then
    echo "Google Chrome is already installed: $(google-chrome --version)"
    exit 0
  fi
fi

echo "Google Chrome is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  # macOS: Install via Homebrew cask
  install_brew_cask google-chrome
  echo "Google Chrome installed successfully"
else
  # Linux: Download and install .deb package
  ensure_wget_installed

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"
  wget -q -O google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  maybe_sudo dpkg -i google-chrome-stable_current_amd64.deb

  # Fix any dependency issues
  maybe_sudo apt install -f -y

  echo "Google Chrome installed successfully: $(google-chrome --version)"
fi
