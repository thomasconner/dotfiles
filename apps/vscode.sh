#!/usr/bin/env bash

set -euo pipefail

echo "Visual Studio Code installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

# Check if VS Code is already installed
if command -v code >/dev/null 2>&1; then
  echo "Visual Studio Code is already installed: $(code --version | head -n1)"
  exit 0
fi

echo "Visual Studio Code is not installed. Installing..."

# Ensure wget is available
ensure_wget_installed
ensure_gpg_installed

# Add Microsoft GPG key and repository
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Clean up temporary files
rm packages.microsoft.gpg

# Update package list and install VS Code
sudo apt update
sudo apt install -y code

echo "Visual Studio Code installed successfully: $(code --version | head -n1)"
