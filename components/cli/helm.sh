#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Helm"

OS=$(detect_os)
ARCH=$(detect_arch)

if command -v helm >/dev/null 2>&1; then
  log_info "helm is already installed: $(helm version --short 2>/dev/null | head -n1)"
  exit 0
fi

log_info "helm is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install helm
  log_success "helm installed: $(helm version --short 2>/dev/null | head -n1)"
else
  # Linux: Install from GitHub release
  ensure_curl_installed

  LATEST_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  log_info "Installing helm ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  curl -fsSL "https://get.helm.sh/helm-v${LATEST_VERSION}-linux-${ARCH}.tar.gz" -o helm.tar.gz
  tar -xzf helm.tar.gz
  maybe_sudo install -o root -g root -m 0755 "linux-${ARCH}/helm" /usr/local/bin/helm

  log_success "helm installed: $(helm version --short 2>/dev/null | head -n1)"
fi
