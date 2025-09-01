#!/usr/bin/env bash

set -e

echo "Google Chrome installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

# Check if Chrome is already installed
if command -v google-chrome >/dev/null 2>&1; then
  echo "Google Chrome is already installed: $(google-chrome --version)"
  exit 0
fi

echo "Google Chrome is not installed. Installing..."

# Ensure wget is available
ensure_wget_installed

# Download and install Chrome
cd /tmp
wget -q -O google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

# Fix any dependency issues
sudo apt-get install -f -y

# Clean up
rm -f google-chrome-stable_current_amd64.deb

echo "Google Chrome installed successfully: $(google-chrome --version)"
