#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing shellcheck"

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v shellcheck >/dev/null 2>&1; then
        log_info "shellcheck is already installed: $(shellcheck --version | head -2 | tail -1)"
        exit 0
    fi
fi

log_info "shellcheck is not installed. Installing..."
install_package shellcheck
log_success "shellcheck installed: $(shellcheck --version | head -2 | tail -1)"
