#!/usr/bin/env bash

set -euo pipefail

echo "Docker installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1; then
  echo "Docker is already installed: $(docker --version)"
  exit 0
fi

echo "Docker is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  # macOS: Install via Homebrew cask
  install_brew_cask docker
  echo "Docker installed successfully"
  echo "Please launch Docker.app to complete setup"
else
  # Linux: Install Docker Engine via apt (official method from docs.docker.com)
  ensure_curl_installed

  echo "Installing Docker Engine for Linux..."

  # Install prerequisites
  maybe_sudo apt update
  maybe_sudo apt install -y ca-certificates curl

  # Add Docker's official GPG key
  maybe_sudo install -m 0755 -d /etc/apt/keyrings
  maybe_sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  maybe_sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Get Ubuntu codename (handles derivatives like Linux Mint)
  CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")

  # Add the repository to apt sources
  echo "Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc" | maybe_sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

  # Install Docker packages
  maybe_sudo apt update
  maybe_sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Add current user to docker group (if not root)
  if [[ $EUID -ne 0 ]]; then
    maybe_sudo usermod -aG docker "$USER"
    echo "Added $USER to docker group. Log out and back in for this to take effect."
  fi

  echo "Docker installed: $(docker --version)"
fi
