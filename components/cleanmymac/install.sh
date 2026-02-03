#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing CleanMyMac"

OS=$(detect_os)

# Check if CleanMyMac is already installed
if [[ "$OS" == "macos" ]]; then
  if [[ -d "/Applications/CleanMyMac.app" ]] || [[ -d "/Applications/CleanMyMac_5.app" ]]; then
    log_info "CleanMyMac is already installed"
    exit 0
  fi
else
  # Linux: CleanMyMac is macOS only
  log_warning "CleanMyMac is only available for macOS"
  log_info "For Linux system cleanup, consider BleachBit: https://www.bleachbit.org/"
  exit 0
fi

log_info "CleanMyMac is not installed. Installing..."

install_brew_cask cleanmymac
log_success "CleanMyMac installed successfully"
