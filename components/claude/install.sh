#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing Claude Code configuration"

# Early exit if already installed (unless FORCE)
if [[ "${FORCE:-false}" != "true" ]]; then
    if [[ -L "$HOME/.claude/CLAUDE.md" ]] && [[ -e "$HOME/.claude/CLAUDE.md" ]]; then
        log_info "Claude Code configuration is already installed"
        exit 0
    fi
fi

# Ensure ~/.claude directory exists
run_cmd mkdir -p "${HOME}/.claude"

# Symlink configuration files
safe_symlink "$SCRIPT_DIR/CLAUDE.md" "${HOME}/.claude/CLAUDE.md"
safe_symlink "$SCRIPT_DIR/settings.json" "${HOME}/.claude/settings.json"
safe_symlink "$SCRIPT_DIR/settings.local.json" "${HOME}/.claude/settings.local.json"

log_success "Claude Code configuration complete"
