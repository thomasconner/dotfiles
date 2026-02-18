#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Bun"

OS=$(detect_os)

check_installed_cmd "bun" "bun --version" && exit 0

log_info "Bun is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
    ensure_brew_installed
    run_cmd brew install oven-sh/bun/bun
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
        log_success "Bun installed: $(bun --version)"
    fi
else
    # Linux: Use official installer
    ensure_curl_installed

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: curl -fsSL https://bun.sh/install | bash"
    else
        curl -fsSL https://bun.sh/install | bash

        # Verify installation
        if command -v bun >/dev/null 2>&1; then
            log_success "Bun installed: $(bun --version)"
        else
            # The installer adds to ~/.bun/bin which may not be in PATH yet
            if [[ -x "$HOME/.bun/bin/bun" ]]; then
                log_success "Bun installed to ~/.bun/bin/bun"
                log_info "Add ~/.bun/bin to your PATH to use 'bun' command"
            else
                log_error "Bun installation may have failed. Check output above."
                exit 1
            fi
        fi
    fi
fi
