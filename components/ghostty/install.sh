#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)
PM=$(get_package_manager)

if ! check_installed_cmd "ghostty" "ghostty --version"; then
  log_info "Installing Ghostty"

  if [[ "$OS" == "macos" ]]; then
    install_brew_cask ghostty
    log_success "Ghostty installed successfully"

  elif [[ "$PM" == "apt" ]]; then
    # Ubuntu/Debian: Use community-maintained ghostty-ubuntu installer
    log_info "Installing Ghostty via ghostty-ubuntu installer..."
    log_info "This uses the community package from github.com/mkasberg/ghostty-ubuntu"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"

    if command -v ghostty >/dev/null 2>&1; then
      log_success "Ghostty installed successfully: $(ghostty --version)"
    else
      log_error "Ghostty installation failed"
      exit 1
    fi

  elif [[ "$PM" == "pacman" ]]; then
    # Arch Linux: Official package
    log_info "Installing Ghostty via pacman..."
    maybe_sudo pacman -S --noconfirm ghostty
    log_success "Ghostty installed successfully: $(ghostty --version)"

  elif [[ "$PM" == "dnf" ]]; then
    # Fedora: Currently no official package, point to build instructions
    log_warning "Ghostty does not have an official Fedora package"
    log_info "You can build from source: https://ghostty.org/docs/install/build"
    log_info "Or check for community packages: https://ghostty.org/docs/install/binary"

  else
    log_warning "Ghostty installation not supported for package manager: $PM"
    log_info "Please install manually: https://ghostty.org/docs/install"
  fi
fi

# Symlink Ghostty config
CONFIG_DIR="${HOME}/.config/ghostty"
if [[ ! -d "$CONFIG_DIR" ]]; then
  run_cmd mkdir -p "$CONFIG_DIR"
fi

safe_symlink "$SCRIPT_DIR/config" "$CONFIG_DIR/config"
log_success "Ghostty configuration complete"
