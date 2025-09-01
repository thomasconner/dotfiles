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

# Download and install Slack
cd /tmp
wget -O slack-desktop.deb https://downloads.slack-edge.com/releases/linux/4.38.125/prod/x64/slack-desktop-4.38.125-amd64.deb
sudo dpkg -i slack-desktop.deb

# Fix any dependency issues
sudo apt-get install -f -y

# Clean up
rm -f slack-desktop.deb

echo "Slack installed successfully"
