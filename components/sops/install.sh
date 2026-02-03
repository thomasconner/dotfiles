#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing sops (secrets management)"

OS=$(detect_os)
ARCH=$(detect_arch)

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v sops >/dev/null 2>&1; then
        log_info "sops is already installed: $(sops --version 2>&1 | head -n1)"
        exit 0
    fi
fi

log_info "sops is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install sops
  log_success "sops installed: $(sops --version 2>&1 | head -n1)"
else
  # Linux: Install from GitHub release
  ensure_curl_installed

  LATEST_VERSION=$(github_latest_version "getsops/sops") || exit 1
  log_info "Installing sops ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  BINARY_NAME="sops-v${LATEST_VERSION}.linux.${ARCH}"
  curl -fsSL "https://github.com/getsops/sops/releases/download/v${LATEST_VERSION}/${BINARY_NAME}" -o "$BINARY_NAME"
  curl -fsSL "https://github.com/getsops/sops/releases/download/v${LATEST_VERSION}/sops-v${LATEST_VERSION}.checksums.txt" -o checksums.txt

  log_info "Verifying checksum..."
  verify_checksum_from_file "$BINARY_NAME" checksums.txt || exit 1

  maybe_sudo install -o root -g root -m 0755 "$BINARY_NAME" /usr/local/bin/sops

  log_success "sops installed: $(sops --version 2>&1 | head -n1)"
fi
