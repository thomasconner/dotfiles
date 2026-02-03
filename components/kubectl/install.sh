#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing kubectl"

OS=$(detect_os)
ARCH=$(detect_arch)

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v kubectl >/dev/null 2>&1; then
        log_info "kubectl is already installed: $(kubectl version --client 2>/dev/null | head -n1)"
        exit 0
    fi
fi

log_info "kubectl is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install kubectl
  log_success "kubectl installed: $(kubectl version --client 2>/dev/null | head -n1)"
else
  # Linux: Install from official binary
  ensure_curl_installed

  LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  log_info "Installing kubectl ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl"
  curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

  maybe_sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

  log_success "kubectl installed: $(kubectl version --client 2>/dev/null | head -n1)"
fi
