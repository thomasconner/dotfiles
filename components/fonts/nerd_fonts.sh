#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Nerd Fonts"

OS=$(detect_os)

# Nerd Fonts to install
FONTS=("FiraCode" "JetBrainsMono" "Hack" "Ubuntu" "UbuntuMono")

if [[ "$OS" == "macos" ]]; then
  # macOS: Install via Homebrew cask fonts
  ensure_brew_installed

  for FONT in "${FONTS[@]}"; do
    # Convert to Homebrew cask naming (lowercase, prefixed)
    CASK_NAME="font-${FONT,,}-nerd-font"
    # Fix casing for multi-word names
    CASK_NAME=$(echo "$CASK_NAME" | sed 's/jetbrainsmono/jetbrains-mono/g; s/ubuntumono/ubuntu-mono/g')

    if brew list --cask "$CASK_NAME" &>/dev/null; then
      log_info "$FONT Nerd Font already installed via Homebrew"
    else
      log_info "Installing $FONT Nerd Font via Homebrew..."
      run_cmd brew install --cask "$CASK_NAME"
    fi
  done
else
  # Linux: Download from GitHub releases
  VERSION="3.4.0"
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  ensure_wget_installed
  ensure_unzip_installed

  for FONT in "${FONTS[@]}"; do
    FONT_FILE=$(find "$FONT_DIR" \( -iname "${FONT}*.ttf" -o -iname "${FONT}*.otf" \) -print -quit 2>/dev/null)

    if [ -n "$FONT_FILE" ]; then
      log_info "$FONT already installed at $FONT_FILE, skipping..."
      continue
    fi

    ZIP_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v$VERSION/${FONT}.zip"
    TMP_ZIP="/tmp/${FONT}.zip"

    log_info "Downloading $FONT Nerd Font..."

    if ! wget -q "$ZIP_URL" -O "$TMP_ZIP"; then
      log_error "Failed to download $FONT"
      continue
    fi

    log_info "Extracting $FONT..."
    unzip -oq "$TMP_ZIP" -d "$FONT_DIR"

    rm -f "$TMP_ZIP"
  done

  # Refresh font cache
  if command -v fc-cache &>/dev/null; then
    log_info "Updating font cache..."
    fc-cache -fv "$FONT_DIR"
  fi
fi

log_success "Nerd Fonts installation complete"
