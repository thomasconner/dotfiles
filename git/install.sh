#!/usr/bin/env bash

set -euo pipefail

echo "git configuration"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

# Ensure git is installed
ensure_git_installed

# Check if the file exists
if [ ! -f "${HOME}/.gitconfig.local" ]; then
  cp "$SCRIPT_DIR/.gitconfig.local" "${HOME}/.gitconfig.local"
  echo "git configuration: created ${HOME}/.gitconfig.local - Please update it!!"
fi

ln -sf "$SCRIPT_DIR/.gitconfig" "${HOME}/.gitconfig"
ln -sf "$SCRIPT_DIR/.gitignore" "${HOME}/.gitignore"
