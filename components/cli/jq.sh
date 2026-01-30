#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing jq"

if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v jq >/dev/null 2>&1; then
        log_info "jq is already installed: $(jq --version)"
        exit 0
    fi
fi

log_info "jq is not installed. Installing..."
install_package jq
log_success "jq installed: $(jq --version)"
