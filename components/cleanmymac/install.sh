#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

if [[ "$OS" == "macos" ]]; then
  log_info "Installing CleanMyMac"

  if [[ -d "/Applications/CleanMyMac.app" ]] || [[ -d "/Applications/CleanMyMac X.app" ]]; then
    log_info "CleanMyMac is already installed"
    exit 0
  fi

  install_brew_cask cleanmymac
  log_success "CleanMyMac installed"

else
  # Linux: Install BleachBit as alternative
  log_info "Installing BleachBit (CleanMyMac alternative for Linux)"

  if command -v bleachbit >/dev/null 2>&1; then
    log_info "BleachBit is already installed"
    exit 0
  fi

  install_package bleachbit
  log_success "BleachBit installed"
fi
