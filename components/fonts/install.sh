#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing fonts"

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

"$SCRIPT_DIR/nerd_fonts.sh"

log_success "Fonts installation complete"
