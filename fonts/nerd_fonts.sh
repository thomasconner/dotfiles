#!/usr/bin/env bash

set -e

echo "Nerd Fonts installation"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

# Nerd Fonts to install
FONTS=("FiraCode" "JetBrainsMono" "Hack" "Ubuntu" "UbuntuMono")

# Version of Nerd Fonts release
VERSION="3.4.0"

# Install location
FONT_DIR="$HOME/.local/share/fonts"

mkdir -p "$FONT_DIR"

ensure_wget_installed
ensure_unzip_installed

for FONT in "${FONTS[@]}"; do
  FONT_FILE=$(find "$FONT_DIR" -iname "${FONT}*.ttf" -o -iname "${FONT}*.otf" | head -n 1)

  if [ -n "$FONT_FILE" ]; then
    echo "$FONT already installed at $FONT_FILE, skipping..."
    continue
  fi

  ZIP_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v$VERSION/${FONT}.zip"
  TMP_ZIP="/tmp/${FONT}.zip"

  echo "Downloading $FONT Nerd Font..."

  if ! wget -q "$ZIP_URL" -O "$TMP_ZIP"; then
    echo "❌ Failed to download $FONT"
    continue
  fi

  echo "Extracting $FONT..."
  unzip -oq "$TMP_ZIP" -d "$FONT_DIR"

  echo "Cleaning up $TMP_ZIP..."
  rm -f "$TMP_ZIP"
done

# Refresh font cache (Linux only)
if command -v fc-cache &>/dev/null; then
  echo "Updating font cache..."
  fc-cache -fv "$FONT_DIR"
fi

echo "All selected Nerd Fonts installed!"
