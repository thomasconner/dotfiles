#!/usr/bin/env bash

set -e

echo "warp-terminal installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

# Check if WARP is already installed
if command -v warp-terminal >/dev/null 2>&1; then
  echo "warp terminal is already installed"
  exit 0
fi

echo "warp-terminal is not installed. Installing..."

ensure_wget_installed
ensure_gpg_installed

# Add GPG key and repository
wget -qO- https://releases.warp.dev/linux/keys/warp.asc | gpg --dearmor > warpdotdev.gpg
sudo install -D -o root -g root -m 644 warpdotdev.gpg /etc/apt/keyrings/warpdotdev.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/warpdotdev.gpg] https://releases.warp.dev/linux/deb stable main" > /etc/apt/sources.list.d/warpdotdev.list'

# Clean up temporary files
rm warpdotdev.gpg

# Update package list and install warp-terminal
sudo apt update
sudo apt install warp-terminal

echo "warp-terminal installed successfully"
