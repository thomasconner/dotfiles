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
    # Ubuntu/Debian: Use community-maintained ghostty-ubuntu package
    log_info "Installing Ghostty via ghostty-ubuntu repository..."

    # Add the ghostty PPA
    if [[ ! -f /etc/apt/sources.list.d/ghostty.list ]]; then
      # Determine Ubuntu codename (handle derivatives like Linux Mint)
      if [[ -f /etc/upstream-release/lsb-release ]]; then
        # Linux Mint and other Ubuntu derivatives
        CODENAME=$(grep DISTRIB_CODENAME /etc/upstream-release/lsb-release | cut -d= -f2)
      elif grep -q UBUNTU_CODENAME /etc/os-release 2>/dev/null; then
        CODENAME=$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)
      else
        CODENAME=$(lsb_release -cs 2>/dev/null || echo "noble")
      fi
      log_info "Using Ubuntu codename: $CODENAME"

      ensure_wget_installed
      log_info "Adding Ghostty GPG key..."
      maybe_sudo mkdir -p /etc/apt/keyrings
      wget -qO- https://ppa.launchpadcontent.net/mkasberg/ghostty/ubuntu/dists/"${CODENAME}"/Release.gpg | \
        maybe_sudo tee /etc/apt/keyrings/ghostty-archive-keyring.asc >/dev/null

      log_info "Adding Ghostty apt repository..."
      echo "deb [signed-by=/etc/apt/keyrings/ghostty-archive-keyring.asc] https://ppa.launchpadcontent.net/mkasberg/ghostty/ubuntu $CODENAME main" | \
        maybe_sudo tee /etc/apt/sources.list.d/ghostty.list >/dev/null

      log_info "Updating apt cache..."
      maybe_sudo apt update
    fi

    maybe_sudo apt install -y ghostty
    log_success "Ghostty installed successfully: $(ghostty --version)"

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
