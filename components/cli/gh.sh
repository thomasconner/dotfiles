#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing GitHub CLI (gh)"

OS=$(detect_os)
PM=$(get_package_manager)

if command -v gh >/dev/null 2>&1; then
  log_info "gh is already installed: $(gh --version | head -n1)"
  exit 0
fi

log_info "gh is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install gh
  log_success "gh installed: $(gh --version | head -n1)"
elif [[ "$PM" == "apt" ]]; then
  ensure_curl_installed
  ensure_gpg_installed

  # Add GitHub CLI repository
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | maybe_sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | maybe_sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

  maybe_sudo apt update
  maybe_sudo apt install -y gh

  log_success "gh installed: $(gh --version | head -n1)"
elif [[ "$PM" == "dnf" ]]; then
  maybe_sudo dnf install -y gh
  log_success "gh installed: $(gh --version | head -n1)"
elif [[ "$PM" == "pacman" ]]; then
  maybe_sudo pacman -S --noconfirm github-cli
  log_success "gh installed: $(gh --version | head -n1)"
else
  log_warning "gh installation not supported for package manager: $PM"
  log_info "Please install gh manually: https://cli.github.com/"
fi
