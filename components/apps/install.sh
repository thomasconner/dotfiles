#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing applications"

# Check for dry-run mode
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install the following applications:"
    log_info "  - Google Chrome"
    log_info "  - Slack"
    log_info "  - Visual Studio Code"
    log_info "  - Claude"
    log_info "  - 1Password"
    log_info "  - Logi Options+"
    log_info "  - TradingView"
    log_info "  - Linear"
    log_info "  - CleanMyMac"
    log_info "  - DBeaver"
    log_success "Applications dry-run complete"
    exit 0
fi

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
