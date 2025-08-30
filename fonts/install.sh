#!/usr/bin/env bash

set -e

echo "Fonts installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# "$SCRIPT_DIR/jetbrains_mono.sh"
"$SCRIPT_DIR/nerd_fonts.sh"
