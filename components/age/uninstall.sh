#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

OS=$(detect_os)

log_info "Uninstalling age..."

if [[ "$OS" == "macos" ]]; then
    run_cmd brew uninstall age || true
else
    [[ -f "/usr/local/bin/age" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/age
    [[ -f "/usr/local/bin/age-keygen" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/age-keygen
fi
