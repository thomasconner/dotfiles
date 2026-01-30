#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Claude Code CLI"

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v claude >/dev/null 2>&1; then
        log_info "Claude Code is already installed: $(claude --version 2>/dev/null || echo 'unknown version')"
        exit 0
    fi
fi

log_info "Claude Code is not installed. Installing via native installer..."

# Use the native installer (recommended) - works on macOS and Linux
# Auto-updates are included with native installation
ensure_curl_installed
curl -fsSL https://claude.ai/install.sh | bash

# Verify installation
if command -v claude >/dev/null 2>&1; then
  log_success "Claude Code installed: $(claude --version 2>/dev/null || echo 'installed')"
else
  # The installer adds to ~/.local/bin which may not be in PATH yet
  if [[ -x "$HOME/.local/bin/claude" ]]; then
    log_success "Claude Code installed to ~/.local/bin/claude"
    log_info "Add ~/.local/bin to your PATH to use 'claude' command"
  else
    log_error "Claude Code installation may have failed. Check output above."
    exit 1
  fi
fi
