#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing ChatGPT desktop app"

OS=$(detect_os)

if [[ "$OS" == "macos" ]]; then
    # Check if already installed
    if [[ "${FORCE:-false}" != "true" ]] && [[ -d "/Applications/ChatGPT.app" ]]; then
        log_info "ChatGPT is already installed"
        exit 0
    fi

    log_info "Installing ChatGPT via Homebrew..."
    install_brew_cask chatgpt
    log_success "ChatGPT desktop app installed successfully"
else
    log_warning "ChatGPT desktop app is not available on Linux"
    log_info "Create a Chrome web app at https://chatgpt.com instead"
    exit 2
fi

log_success "ChatGPT desktop app installation complete"
