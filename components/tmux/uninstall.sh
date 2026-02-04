#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling tmux..."

PM=$(get_package_manager)

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall tmux || true
elif [[ "$PM" == "apt" ]]; then
    run_cmd maybe_sudo apt remove -y tmux || true
fi

# Remove config
[[ -L "$HOME/.tmux.conf" ]] && run_cmd rm -f "$HOME/.tmux.conf"
