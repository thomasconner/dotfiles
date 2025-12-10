#!/usr/bin/env bash

set -euo pipefail

echo "Visual Studio Code installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if VS Code is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for VS Code in Applications or via command
  if [[ -d "/Applications/Visual Studio Code.app" ]] || command -v code >/dev/null 2>&1; then
    echo "Visual Studio Code is already installed"
    if command -v code >/dev/null 2>&1; then
      echo "Version: $(code --version | head -n1)"
    fi
    exit 0
  fi
else
  if command -v code >/dev/null 2>&1; then
    echo "Visual Studio Code is already installed: $(code --version | head -n1)"
    exit 0
  fi
fi

echo "Visual Studio Code is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  # macOS: Install via Homebrew cask
  install_brew_cask visual-studio-code
  echo "Visual Studio Code installed successfully"
  echo "Run 'code' from the terminal to open VS Code"
else
  # Linux: Add Microsoft repository and install via apt
  ensure_wget_installed
  ensure_gpg_installed

  # Add Microsoft GPG key and repository
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  maybe_sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
  maybe_sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

  # Clean up temporary files
  rm packages.microsoft.gpg

  # Update package list and install VS Code
  maybe_sudo apt update
  maybe_sudo apt install -y code

  echo "Visual Studio Code installed successfully: $(code --version | head -n1)"
fi
