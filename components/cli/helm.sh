#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Helm"

OS=$(detect_os)
ARCH=$(detect_arch)

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v helm >/dev/null 2>&1; then
        log_info "helm is already installed: $(helm version --short 2>/dev/null | head -n1)"
        exit 0
    fi
fi

log_info "helm is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install helm
  log_success "helm installed: $(helm version --short 2>/dev/null | head -n1)"
else
  # Linux: Install from GitHub release
  ensure_curl_installed

  LATEST_VERSION=$(github_latest_version "helm/helm") || exit 1
  log_info "Installing helm ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  ARCHIVE_NAME="helm-v${LATEST_VERSION}-linux-${ARCH}.tar.gz"
  curl -fsSL "https://get.helm.sh/${ARCHIVE_NAME}" -o "$ARCHIVE_NAME"
  curl -fsSL "https://get.helm.sh/${ARCHIVE_NAME}.sha256sum" -o "${ARCHIVE_NAME}.sha256sum"

  log_info "Verifying checksum..."
  verify_checksum_from_file "$ARCHIVE_NAME" "${ARCHIVE_NAME}.sha256sum" || exit 1

  tar -xzf "$ARCHIVE_NAME"
  maybe_sudo install -o root -g root -m 0755 "linux-${ARCH}/helm" /usr/local/bin/helm

  log_success "helm installed: $(helm version --short 2>/dev/null | head -n1)"
fi
