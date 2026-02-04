#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling git-spice..."

# Installed via go
[[ -f "$HOME/go/bin/gs" ]] && run_cmd rm -f "$HOME/go/bin/gs"

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall git-spice || true
fi
