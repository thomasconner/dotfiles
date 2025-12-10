#!/usr/bin/env bash

set -euo pipefail

echo "Claude desktop app installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if Claude is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for Claude in Applications
  if [[ -d "/Applications/Claude.app" ]]; then
    echo "Claude is already installed"
    exit 0
  fi
else
  # Linux: Claude desktop app is currently macOS only
  echo "Claude desktop app is currently only available for macOS"
  echo "For Linux, use Claude via web at https://claude.ai"
  exit 0
fi

echo "Claude is not installed. Installing..."

# macOS: Install via Homebrew cask
install_brew_cask claude
echo "Claude desktop app installed successfully"
