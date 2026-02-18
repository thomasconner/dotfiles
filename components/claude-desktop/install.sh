#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Claude desktop app"

OS=$(detect_os)

if [[ "$OS" != "macos" ]]; then
  log_warning "Claude desktop app installation not supported on $OS"
  log_info "Use Claude via web at https://claude.ai"
  exit 2
fi

check_installed_app "Claude" && exit 0

log_info "Claude is not installed. Installing..."

install_brew_cask claude
log_success "Claude desktop app installed successfully"
