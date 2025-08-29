#!/usr/bin/env bash

set -e

echo "🚀 tmux installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v tmux >/dev/null 2>&1; then
  echo "tmux is installed: $(tmux -V)"
else
  sudo apt update && sudo apt install -y tmux
fi

if [ ! -f "${HOME}/.tmux.conf" ]; then
  cp "$SCRIPT_DIR/.tmux.conf" "${HOME}/.tmux.conf"
  echo "ℹ️ tmux configuration: created ${HOME}/.tmux.conf"
fi

if tmux ls >/dev/null 2>&1; then
  tmux source-file "${HOME}/.tmux.conf"
  echo "Reloaded tmux config for running server."
else
  echo "No tmux server running; nothing to reload."
fi
