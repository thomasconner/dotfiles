#!/usr/bin/env bash

set -e

echo "Apps installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/tmux/install.sh"
"$SCRIPT_DIR/chrome.sh"
"$SCRIPT_DIR/slack.sh"
"$SCRIPT_DIR/vscode.sh"
