#!/usr/bin/env bash

set -e

echo "tmux installation"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/utils.sh"

if command -v tmux >/dev/null 2>&1; then
  echo "tmux is installed: $(tmux -V)"
else
  sudo apt update
  sudo apt install -y tmux
fi

ln -sf "$SCRIPT_DIR/.tmux.conf" "${HOME}/.tmux.conf"
echo "tmux configuration: symlinked ${HOME}/.tmux.conf"

if tmux ls >/dev/null 2>&1; then
  tmux source-file "${HOME}/.tmux.conf"
  echo "Reloaded tmux config for running server."
fi
