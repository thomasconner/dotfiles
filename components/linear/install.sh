#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Linear"

OS=$(detect_os)

if [[ "$OS" != "macos" ]]; then
  log_warning "Linear desktop app installation not supported on $OS"
  log_info "Use Linear via web at https://linear.app"
  exit 2
fi

check_installed_app "Linear" && exit 0

log_info "Linear is not installed. Installing..."

install_brew_cask linear-linear
log_success "Linear installed successfully"
