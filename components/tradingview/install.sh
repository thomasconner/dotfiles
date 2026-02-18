#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

# Download URLs
LINUX_DEB_URL="https://tvd-packages.tradingview.com/stable/latest/linux/TradingView.deb"

if [[ "$OS" == "macos" ]]; then
  # Check if already installed
  if [[ "${FORCE:-false}" != "true" ]] && [[ -d "/Applications/TradingView.app" ]]; then
    log_info "TradingView already installed"
    exit 0
  fi

  install_brew_cask tradingview

  # Remove quarantine flag — TradingView's Electron app hangs on macOS
  # during Gatekeeper assessment without this
  xattr -dr com.apple.quarantine "/Applications/TradingView.app" 2>/dev/null || true

  log_success "TradingView installed"

elif [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "linuxmint" ]]; then
  # Check if already installed
  if command -v tradingview >/dev/null 2>&1 || dpkg -l tradingview &>/dev/null; then
    log_info "TradingView already installed"
    exit 0
  fi

  log_step "Downloading TradingView for Linux..."
  TEMP_DEB=$(mktemp /tmp/TradingView.XXXXXX.deb)
  run_cmd curl -fSL -o "$TEMP_DEB" "$LINUX_DEB_URL"

  log_step "Installing TradingView..."
  run_cmd maybe_sudo dpkg -i "$TEMP_DEB" || run_cmd maybe_sudo apt-get install -f -y
  rm -f "$TEMP_DEB"

  log_success "TradingView installed"

else
  log_warning "TradingView desktop app installation not supported on $OS"
  log_info "Download from https://www.tradingview.com/desktop/"
  exit 2
fi
