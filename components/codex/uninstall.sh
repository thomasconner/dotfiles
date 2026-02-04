#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling Codex CLI..."

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall --cask codex || log_warning "Could not uninstall via brew"
else
    if command -v npm >/dev/null 2>&1; then
        run_cmd npm uninstall -g @openai/codex || true
    fi
fi
