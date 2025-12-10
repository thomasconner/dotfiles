#!/usr/bin/env bash

set -euo pipefail

echo "Apps installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/tmux/install.sh"
"$SCRIPT_DIR/chrome.sh"
"$SCRIPT_DIR/slack.sh"
"$SCRIPT_DIR/vscode.sh"
"$SCRIPT_DIR/claude.sh"
"$SCRIPT_DIR/claude-code.sh"
"$SCRIPT_DIR/1password.sh"
"$SCRIPT_DIR/logi-options.sh"
"$SCRIPT_DIR/tradingview.sh"
"$SCRIPT_DIR/linear.sh"
"$SCRIPT_DIR/cleanmymac.sh"
