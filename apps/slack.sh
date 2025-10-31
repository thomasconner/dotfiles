#!/usr/bin/env bash

set -e

echo "Slack installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

# Check if Slack is already installed
if command -v slack >/dev/null 2>&1; then
  echo "Slack is already installed: $(slack --version 2>/dev/null || echo 'version unknown')"
  exit 0
fi

echo "Slack is not installed. Installing..."

ensure_wget_installed

# Download and install Slack (latest version)
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
wget -O slack-desktop.deb https://downloads.slack-edge.com/releases/linux/slack-desktop-amd64.deb
sudo dpkg -i slack-desktop.deb

# Fix any dependency issues
sudo apt install -f -y

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo "Slack installed successfully"
