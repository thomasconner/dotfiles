#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Linear"

OS=$(detect_os)

# Check if Linear is already installed
if [[ "$OS" == "macos" ]]; then
  if [[ -d "/Applications/Linear.app" ]]; then
    log_info "Linear is already installed"
    exit 0
  fi
else
  log_warning "Linear desktop app installation not supported on $OS"
  log_info "Use Linear via web at https://linear.app"
  exit 2
fi

log_info "Linear is not installed. Installing..."

install_brew_cask linear-linear
log_success "Linear installed successfully"
