#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling terraform..."

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall terraform || true
else
    [[ -f "/usr/local/bin/terraform" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/terraform
fi
