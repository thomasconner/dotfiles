#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Uninstalling Node.js (nodenv)..."

if [[ -d "$HOME/.nodenv" ]]; then
    run_cmd rm -rf "$HOME/.nodenv"
fi
