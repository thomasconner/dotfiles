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
  # Linux: Linear desktop app is macOS only
  log_warning "Linear desktop app is only available for macOS"
  log_info "For Linux, use Linear via web at https://linear.app"
  exit 0
fi

log_info "Linear is not installed. Installing..."

install_brew_cask linear-linear
log_success "Linear installed successfully"
