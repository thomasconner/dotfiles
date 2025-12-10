#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing sops (secrets management)"

OS=$(detect_os)
ARCH=$(detect_arch)

if command -v sops >/dev/null 2>&1; then
  log_info "sops is already installed: $(sops --version 2>&1 | head -n1)"
  exit 0
fi

log_info "sops is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install sops
  log_success "sops installed: $(sops --version 2>&1 | head -n1)"
else
  # Linux: Install from GitHub release
  ensure_curl_installed

  LATEST_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  log_info "Installing sops ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  curl -sL "https://github.com/getsops/sops/releases/download/v${LATEST_VERSION}/sops-v${LATEST_VERSION}.linux.${ARCH}" -o sops
  maybe_sudo install -o root -g root -m 0755 sops /usr/local/bin/sops

  log_success "sops installed: $(sops --version 2>&1 | head -n1)"
fi
