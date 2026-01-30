#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/utils.sh"

log_step "Installing Claude Code configuration"

if [[ "${FORCE:-false}" != "true" ]]; then
    if [[ -L "$HOME/.claude/CLAUDE.md" ]] && [[ -e "$HOME/.claude/CLAUDE.md" ]]; then
        log_info "Claude Code configuration already installed"
        exit 0
    fi
fi

run_cmd mkdir -p "$HOME/.claude"

safe_symlink "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
safe_symlink "$SCRIPT_DIR/settings.json" "$HOME/.claude/settings.json"
safe_symlink "$SCRIPT_DIR/settings.local.json" "$HOME/.claude/settings.local.json"

log_success "Claude Code configuration complete"
