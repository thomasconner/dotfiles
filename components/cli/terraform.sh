#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Terraform"

OS=$(detect_os)
PM=$(get_package_manager)

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v terraform >/dev/null 2>&1; then
        log_info "terraform is already installed: $(terraform version | head -n1)"
        exit 0
    fi
fi

log_info "terraform is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install terraform
  log_success "terraform installed: $(terraform version | head -n1)"
elif [[ "$PM" == "apt" ]]; then
  ensure_curl_installed
  ensure_gpg_installed

  # Get codename from os-release
  CODENAME=""
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  fi

  if [ -z "$CODENAME" ]; then
    log_error "Could not determine distribution codename"
    exit 1
  fi

  # Add HashiCorp GPG key and repository
  curl -fsSL https://apt.releases.hashicorp.com/gpg | maybe_sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $CODENAME main" | maybe_sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

  maybe_sudo apt update
  maybe_sudo apt install -y terraform

  log_success "terraform installed: $(terraform version | head -n1)"
elif [[ "$PM" == "dnf" ]]; then
  maybe_sudo dnf install -y dnf-plugins-core
  maybe_sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
  maybe_sudo dnf install -y terraform
  log_success "terraform installed: $(terraform version | head -n1)"
elif [[ "$PM" == "pacman" ]]; then
  maybe_sudo pacman -S --noconfirm terraform
  log_success "terraform installed: $(terraform version | head -n1)"
else
  log_warning "terraform installation not supported for package manager: $PM"
  log_info "Please install terraform manually: https://developer.hashicorp.com/terraform/downloads"
fi
