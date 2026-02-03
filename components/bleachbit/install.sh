#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

if [[ "$OS" == "macos" ]]; then
  log_warning "BleachBit installation not supported on $OS"
  log_info "For macOS, run: ctdev install cleanmymac"
  exit 2
fi

log_info "Installing BleachBit"

if command -v bleachbit >/dev/null 2>&1; then
  log_info "BleachBit is already installed"
  exit 0
fi

install_package bleachbit
log_success "BleachBit installed"
