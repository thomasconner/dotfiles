#!/usr/bin/env bash

set -euo pipefail

echo "Linear installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if Linear is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for Linear in Applications
  if [[ -d "/Applications/Linear.app" ]]; then
    echo "Linear is already installed"
    exit 0
  fi
else
  # Linux: Linear desktop app is currently macOS only
  echo "Linear desktop app is currently only available for macOS"
  echo "For Linux, use Linear via web at https://linear.app"
  exit 0
fi

echo "Linear is not installed. Installing..."

# macOS: Install via Homebrew cask
install_brew_cask linear-linear
echo "Linear installed successfully"
