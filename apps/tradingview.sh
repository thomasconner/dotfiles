#!/usr/bin/env bash

set -euo pipefail

echo "TradingView installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Check if TradingView is already installed
if [[ "$OS" == "macos" ]]; then
  # On macOS, check for TradingView in Applications
  if [[ -d "/Applications/TradingView.app" ]]; then
    echo "TradingView is already installed"
    exit 0
  fi
else
  # Linux: TradingView desktop app is currently macOS only via Homebrew
  echo "TradingView desktop app is currently only available for macOS via Homebrew"
  echo "For Linux, use TradingView via web at https://www.tradingview.com"
  exit 0
fi

echo "TradingView is not installed. Installing..."

# macOS: Install via Homebrew cask
install_brew_cask tradingview
echo "TradingView installed successfully"
