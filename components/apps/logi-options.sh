#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Logi Options+"

OS=$(detect_os)

# Check if Logi Options+ is already installed
if [[ "$OS" == "macos" ]]; then
  if [[ -d "/Applications/Logi Options+.app" ]]; then
    log_info "Logi Options+ is already installed"
    exit 0
  fi
else
  # Linux: Logi Options+ is macOS/Windows only
  log_warning "Logi Options+ is only available for macOS and Windows"
  log_info "For Linux Logitech device support, consider Solaar: https://pwr-solaar.github.io/Solaar/"
  exit 0
fi

log_info "Logi Options+ is not installed. Installing..."

install_brew_cask logi-options+
log_success "Logi Options+ installed successfully"
