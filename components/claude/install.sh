#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing Claude Code configuration"

# Ensure ~/.claude directory exists
run_cmd mkdir -p "${HOME}/.claude"

# Symlink configuration files
safe_symlink "$SCRIPT_DIR/CLAUDE.md" "${HOME}/.claude/CLAUDE.md"
safe_symlink "$SCRIPT_DIR/settings.json" "${HOME}/.claude/settings.json"
safe_symlink "$SCRIPT_DIR/settings.local.json" "${HOME}/.claude/settings.local.json"

log_success "Claude Code configuration complete"
