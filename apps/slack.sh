#!/usr/bin/env bash

set -euo pipefail

echo "Slack installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if Slack is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for Slack in Applications
  if [[ -d "/Applications/Slack.app" ]]; then
    echo "Slack is already installed"
    exit 0
  fi
else
  if command -v slack >/dev/null 2>&1; then
    echo "Slack is already installed: $(slack --version 2>/dev/null || echo 'version unknown')"
    exit 0
  fi
fi

echo "Slack is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  # macOS: Install via Homebrew cask
  install_brew_cask slack
  echo "Slack installed successfully"
else
  # Linux: Download and install .deb package
  ensure_wget_installed

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"
  wget -O slack-desktop.deb https://downloads.slack-edge.com/releases/linux/slack-desktop-amd64.deb
  maybe_sudo dpkg -i slack-desktop.deb

  # Fix any dependency issues
  maybe_sudo apt install -f -y

  echo "Slack installed successfully"
fi
