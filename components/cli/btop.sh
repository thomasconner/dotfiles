#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing btop (system monitor)"

OS=$(detect_os)
PM=$(get_package_manager)

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v btop >/dev/null 2>&1; then
        log_info "btop is already installed: $(btop --version 2>&1 | head -n1)"
        exit 0
    fi
fi

log_info "btop is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install btop
  log_success "btop installed: $(btop --version 2>&1 | head -n1)"
elif [[ "$PM" == "apt" ]]; then
  maybe_sudo apt update
  maybe_sudo apt install -y btop
  log_success "btop installed: $(btop --version 2>&1 | head -n1)"
elif [[ "$PM" == "dnf" ]]; then
  maybe_sudo dnf install -y btop
  log_success "btop installed: $(btop --version 2>&1 | head -n1)"
elif [[ "$PM" == "pacman" ]]; then
  maybe_sudo pacman -S --noconfirm btop
  log_success "btop installed: $(btop --version 2>&1 | head -n1)"
else
  log_warning "btop installation not supported for package manager: $PM"
  log_info "Please install btop manually: https://github.com/aristocratos/btop"
fi
