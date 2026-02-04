#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

# macOS only
if [[ "$OS" != "macos" ]]; then
    exit 2
fi

log_info "Uninstalling ChatGPT..."
run_cmd brew uninstall --cask chatgpt || log_warning "Could not uninstall via brew"
