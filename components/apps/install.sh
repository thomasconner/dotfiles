#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing applications"

"$SCRIPT_DIR/chrome.sh"
"$SCRIPT_DIR/slack.sh"
"$SCRIPT_DIR/vscode.sh"
"$SCRIPT_DIR/claude.sh"
"$SCRIPT_DIR/1password.sh"
"$SCRIPT_DIR/logi-options.sh"
"$SCRIPT_DIR/tradingview.sh"
"$SCRIPT_DIR/linear.sh"
"$SCRIPT_DIR/cleanmymac.sh"
"$SCRIPT_DIR/dbeaver.sh"

log_success "Applications installation complete"
