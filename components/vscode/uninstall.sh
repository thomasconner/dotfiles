#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling VS Code..."

PM=$(get_package_manager)

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall --cask visual-studio-code || log_warning "Could not uninstall via brew"
elif [[ "$PM" == "apt" ]]; then
    run_cmd maybe_sudo apt remove -y code || true
fi
