#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)
PM=$(get_package_manager)

if [[ "$OS" == "macos" ]]; then
  # macOS: Install iTerm2
  log_info "Installing iTerm2"

  if [[ -d "/Applications/iTerm.app" ]]; then
    log_info "iTerm2 is already installed"
    exit 0
  fi

  install_brew_cask iterm2
  log_success "iTerm2 installed successfully"
else
  # Linux: Install Ghostty
  log_info "Installing Ghostty"

  if command -v ghostty >/dev/null 2>&1; then
    log_info "Ghostty is already installed: $(ghostty --version)"
    exit 0
  fi

  if [[ "$PM" == "apt" ]]; then
    # Ubuntu/Debian: Use community-maintained ghostty-ubuntu installer
    log_info "Installing Ghostty via ghostty-ubuntu installer..."
    log_info "This uses the community package from github.com/mkasberg/ghostty-ubuntu"

    # Use the official install script from ghostty-ubuntu
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
    exit 0

  else
    log_warning "Ghostty installation not supported for package manager: $PM"
    log_info "Please install manually: https://ghostty.org/docs/install"
  fi
fi
