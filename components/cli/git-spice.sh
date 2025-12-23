#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing git-spice (stacked branches for Git)"

OS=$(detect_os)
ARCH=$(detect_arch)

# Check if git-spice is installed (not Ghostscript which also uses 'gs')
if command -v gs >/dev/null 2>&1 && gs --version 2>&1 | grep -q "git-spice"; then
  log_info "git-spice is already installed: $(gs --version 2>&1 | head -n1)"
  exit 0
fi

log_info "git-spice is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  ensure_brew_installed
  brew install git-spice
  log_success "git-spice installed: $(gs --version 2>&1 | head -n1)"
else
  # Linux: Install from GitHub release
  ensure_curl_installed

  # Map architecture to git-spice naming
  case "$ARCH" in
    amd64) GS_ARCH="x86_64" ;;
    arm64) GS_ARCH="aarch64" ;;
    *) GS_ARCH="$ARCH" ;;
  esac

  LATEST_VERSION=$(curl -s https://api.github.com/repos/abhinav/git-spice/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  log_info "Installing git-spice ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"

  curl -fsSL "https://github.com/abhinav/git-spice/releases/download/v${LATEST_VERSION}/git-spice.Linux-${GS_ARCH}.tar.gz" -o git-spice.tar.gz
  tar -xzf git-spice.tar.gz
  maybe_sudo install -o root -g root -m 0755 gs /usr/local/bin/gs

  log_success "git-spice installed: $(gs --version 2>&1 | head -n1)"
fi
