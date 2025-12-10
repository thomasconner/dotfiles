#!/usr/bin/env bash

set -euo pipefail

echo "DBeaver Community Edition installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

# Check if DBeaver is already installed
if command -v dbeaver >/dev/null 2>&1; then
  echo "DBeaver is already installed"
  exit 0
fi

echo "DBeaver is not installed. Installing..."

# Ensure dependencies are available
ensure_wget_installed
ensure_gpg_installed

# Add DBeaver GPG key and repository
wget -qO- https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor > dbeaver.gpg
maybe_sudo install -o root -g root -m 644 dbeaver.gpg /etc/apt/trusted.gpg.d/
maybe_sudo sh -c 'echo "deb [signed-by=/etc/apt/trusted.gpg.d/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" > /etc/apt/sources.list.d/dbeaver.list'

# Clean up temporary files
rm dbeaver.gpg

# Update package list and install DBeaver
maybe_sudo apt update
maybe_sudo apt install -y dbeaver-ce

echo "DBeaver installed successfully"
