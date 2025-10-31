#!/usr/bin/env bash

set -euo pipefail

echo "Fonts installation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/nerd_fonts.sh"
