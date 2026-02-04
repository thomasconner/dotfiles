#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling Nerd Fonts..."

if [[ "$OS" == "macos" ]]; then
    run_cmd rm -f ~/Library/Fonts/*Nerd*
else
    run_cmd rm -rf ~/.local/share/fonts/*Nerd*
fi
