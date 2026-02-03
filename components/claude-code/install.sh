#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Claude Code"

cli_installed=false
config_installed=false

if command -v claude >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/claude" ]]; then
    cli_installed=true
fi

if [[ -L "$HOME/.claude/CLAUDE.md" ]] && [[ -e "$HOME/.claude/CLAUDE.md" ]]; then
    config_installed=true
fi

if [[ "${FORCE:-false}" != "true" ]]; then
    if [[ "$cli_installed" == "true" ]] && [[ "$config_installed" == "true" ]]; then
        log_info "Claude Code is already installed"
        exit 0
    fi
fi

# Install CLI if not present
if [[ "$cli_installed" != "true" ]] || [[ "${FORCE:-false}" == "true" ]]; then
    log_info "Installing Claude Code CLI via native installer..."
    ensure_curl_installed
    curl -fsSL https://claude.ai/install.sh | bash

    if command -v claude >/dev/null 2>&1; then
        log_success "Claude Code CLI installed: $(claude --version 2>/dev/null || echo 'installed')"
    elif [[ -x "$HOME/.local/bin/claude" ]]; then
        log_success "Claude Code CLI installed to ~/.local/bin/claude"
        log_info "Add ~/.local/bin to your PATH to use 'claude' command"
    else
        log_error "Claude Code CLI installation may have failed"
        exit 1
    fi
else
    log_info "Claude Code CLI already installed"
fi

# Install config if not present
if [[ "$config_installed" != "true" ]] || [[ "${FORCE:-false}" == "true" ]]; then
    log_info "Installing Claude Code configuration..."
    run_cmd mkdir -p "$HOME/.claude"
    safe_symlink "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    safe_symlink "$SCRIPT_DIR/settings.json" "$HOME/.claude/settings.json"
    safe_symlink "$SCRIPT_DIR/settings.local.json" "$HOME/.claude/settings.local.json"
    log_success "Claude Code configuration installed"
else
    log_info "Claude Code configuration already installed"
fi

log_success "Claude Code installation complete"
