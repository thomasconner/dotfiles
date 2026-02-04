#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling bun..."

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall bun || true
else
    [[ -d "$HOME/.bun" ]] && run_cmd rm -rf "$HOME/.bun"
fi
