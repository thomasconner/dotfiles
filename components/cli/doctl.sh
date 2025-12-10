#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing doctl (DigitalOcean CLI)"

OS=$(detect_os)
ARCH=$(detect_arch)

if command -v doctl >/dev/null 2>&1; then
  log_info "doctl is already installed: $(doctl version | head -n1)"
  exit 0
fi

log_info "doctl is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install doctl
  log_success "doctl installed: $(doctl version | head -n1)"
else
  # Linux: Install from GitHub release
  ensure_curl_installed

  LATEST_VERSION=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  log_info "Installing doctl ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  curl -sL "https://github.com/digitalocean/doctl/releases/download/v${LATEST_VERSION}/doctl-${LATEST_VERSION}-linux-${ARCH}.tar.gz" | tar -xz
  maybe_sudo install -o root -g root -m 0755 doctl /usr/local/bin/doctl

  log_success "doctl installed: $(doctl version | head -n1)"
fi
