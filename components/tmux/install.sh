#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing tmux"

if ! check_installed_cmd "tmux" "tmux -V"; then
  log_info "Installing tmux..."
  install_package tmux
  log_success "tmux installed: $(tmux -V)"
fi

safe_symlink "$SCRIPT_DIR/.tmux.conf" "${HOME}/.tmux.conf"

if tmux ls >/dev/null 2>&1; then
  tmux source-file "${HOME}/.tmux.conf"
  log_info "Reloaded tmux config for running server"
fi
