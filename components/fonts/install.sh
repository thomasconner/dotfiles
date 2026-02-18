#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing fonts"

# Check for dry-run mode
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install the following Nerd Fonts:"
    log_info "  - FiraCode"
    log_info "  - JetBrainsMono"
    log_info "  - Hack"
    log_info "  - Ubuntu"
    log_info "  - UbuntuMono"
    log_success "Fonts dry-run complete"
    exit 0
fi

# Early exit if already installed (unless FORCE)
if [[ "${FORCE:-false}" != "true" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
        if ls ~/Library/Fonts/*Nerd* >/dev/null 2>&1; then
            log_info "Fonts are already installed"
            exit 0
        fi
    else
        if ls ~/.local/share/fonts/*Nerd* >/dev/null 2>&1; then
            log_info "Fonts are already installed"
            exit 0
        fi
    fi
fi

"$SCRIPT_DIR/nerd_fonts.sh"

log_success "Fonts installation complete"
