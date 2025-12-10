#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing age (file encryption)"

OS=$(detect_os)
ARCH=$(detect_arch)

if command -v age >/dev/null 2>&1; then
  log_info "age is already installed: $(age --version 2>&1 | head -n1)"
  exit 0
fi

log_info "age is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install age
  log_success "age installed: $(age --version 2>&1 | head -n1)"
else
  # Linux: Install from GitHub release
  ensure_curl_installed

  LATEST_VERSION=$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  log_info "Installing age ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  curl -sL "https://github.com/FiloSottile/age/releases/download/v${LATEST_VERSION}/age-v${LATEST_VERSION}-linux-${ARCH}.tar.gz" | tar -xz
  maybe_sudo install -o root -g root -m 0755 age/age /usr/local/bin/age
  maybe_sudo install -o root -g root -m 0755 age/age-keygen /usr/local/bin/age-keygen

  log_success "age installed: $(age --version 2>&1 | head -n1)"
fi
