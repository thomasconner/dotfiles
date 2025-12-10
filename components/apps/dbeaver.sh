#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing DBeaver Community Edition"

OS=$(detect_os)
ARCH=$(detect_arch)
PM=$(get_package_manager)

# Check if DBeaver is already installed
if [[ "$OS" == "macos" ]]; then
  if [[ -d "/Applications/DBeaver.app" ]]; then
    log_info "DBeaver is already installed"
    exit 0
  fi
else
  if command -v dbeaver >/dev/null 2>&1 || command -v dbeaver-ce >/dev/null 2>&1; then
    log_info "DBeaver is already installed"
    exit 0
  fi
fi

log_info "DBeaver is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  install_brew_cask dbeaver-community
  log_success "DBeaver installed successfully"
elif [[ "$PM" == "apt" ]]; then
  # Debian/Ubuntu: Add DBeaver repository and install via apt
  ensure_wget_installed
  ensure_gpg_installed

  # Add DBeaver GPG key and repository
  TEMP_GPG=$(mktemp)
  wget -qO- https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor > "$TEMP_GPG"
  maybe_sudo install -o root -g root -m 644 "$TEMP_GPG" /etc/apt/trusted.gpg.d/dbeaver.gpg
  rm -f "$TEMP_GPG"

  maybe_sudo sh -c 'echo "deb [signed-by=/etc/apt/trusted.gpg.d/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" > /etc/apt/sources.list.d/dbeaver.list'

  maybe_sudo apt update
  maybe_sudo apt install -y dbeaver-ce

  log_success "DBeaver installed successfully"
elif [[ "$PM" == "dnf" ]]; then
  # Fedora: Download and install RPM directly
  if [[ "$ARCH" == "amd64" ]]; then
    ARCH_RPM="x86_64"
  elif [[ "$ARCH" == "arm64" ]]; then
    ARCH_RPM="aarch64"
  else
    log_warning "DBeaver RPM not available for architecture: $ARCH"
    log_info "Please install DBeaver via Flatpak: flatpak install flathub io.dbeaver.DBeaverCommunity"
    exit 0
  fi

  ensure_wget_installed

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  # Get latest version from DBeaver releases
  log_info "Downloading DBeaver RPM..."
  wget -O dbeaver-ce.rpm "https://dbeaver.io/files/dbeaver-ce-latest-stable.${ARCH_RPM}.rpm"
  maybe_sudo dnf install -y ./dbeaver-ce.rpm

  log_success "DBeaver installed successfully"
elif [[ "$PM" == "pacman" ]]; then
  # Arch: Available in community repo
  log_info "Installing DBeaver from community repository..."
  maybe_sudo pacman -S --noconfirm dbeaver
  log_success "DBeaver installed successfully"
else
  log_warning "DBeaver installation not supported for package manager: $PM"
  log_info "Please install DBeaver manually: https://dbeaver.io/download/"
fi
