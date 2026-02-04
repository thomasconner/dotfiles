#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Uninstalling Claude Code..."

# Remove CLI
if [[ -x "$HOME/.local/bin/claude" ]]; then
    run_cmd rm -f "$HOME/.local/bin/claude"
fi

# Remove config symlinks
[[ -L "$HOME/.claude/CLAUDE.md" ]] && run_cmd rm -f "$HOME/.claude/CLAUDE.md"
[[ -L "$HOME/.claude/settings.json" ]] && run_cmd rm -f "$HOME/.claude/settings.json"
[[ -L "$HOME/.claude/settings.local.json" ]] && run_cmd rm -f "$HOME/.claude/settings.local.json"

log_info "~/.claude directory preserved"
