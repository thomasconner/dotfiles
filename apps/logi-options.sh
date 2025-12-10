#!/usr/bin/env bash

set -euo pipefail

echo "Logi Options+ installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if Logi Options+ is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for Logi Options+ in Applications
  if [[ -d "/Applications/Logi Options+.app" ]]; then
    echo "Logi Options+ is already installed"
    exit 0
  fi
else
  # Linux: Logi Options+ is currently macOS only
  echo "Logi Options+ is currently only available for macOS"
  exit 0
fi

echo "Logi Options+ is not installed. Installing..."

# macOS: Install via Homebrew cask
install_brew_cask logi-options+
echo "Logi Options+ installed successfully"
