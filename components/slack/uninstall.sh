#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling Slack..."

PM=$(get_package_manager)

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall --cask slack || log_warning "Could not uninstall via brew"
elif [[ "$PM" == "apt" ]]; then
    run_cmd maybe_sudo apt remove -y slack-desktop || true
fi
