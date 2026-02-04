#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Uninstalling git configuration..."

[[ -L "$HOME/.gitconfig" ]] && run_cmd rm -f "$HOME/.gitconfig"
[[ -L "$HOME/.gitignore" ]] && run_cmd rm -f "$HOME/.gitignore"

log_info ".gitconfig.local preserved"
