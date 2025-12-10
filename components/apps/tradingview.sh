#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing TradingView"

OS=$(detect_os)

# Check if TradingView is already installed
if [[ "$OS" == "macos" ]]; then
  if [[ -d "/Applications/TradingView.app" ]]; then
    log_info "TradingView is already installed"
    exit 0
  fi
else
  # Linux: TradingView desktop app is macOS/Windows only
  log_warning "TradingView desktop app is only available for macOS and Windows"
  log_info "For Linux, use TradingView via web at https://www.tradingview.com"
  exit 0
fi

log_info "TradingView is not installed. Installing..."

install_brew_cask tradingview
log_success "TradingView installed successfully"
