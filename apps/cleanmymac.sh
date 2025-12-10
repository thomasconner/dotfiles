#!/usr/bin/env bash

set -euo pipefail

echo "CleanMyMac installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if CleanMyMac is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for CleanMyMac in Applications
  if [[ -d "/Applications/CleanMyMac.app" ]] || [[ -d "/Applications/CleanMyMac_5.app" ]]; then
    echo "CleanMyMac is already installed"
    exit 0
  fi
else
  # Linux: CleanMyMac is macOS only
  echo "CleanMyMac is only available for macOS"
  exit 0
fi

echo "CleanMyMac is not installed. Installing..."

# macOS: Install via Homebrew cask
install_brew_cask cleanmymac
echo "CleanMyMac installed successfully"
