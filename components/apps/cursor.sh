#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing Cursor AI editor"

OS=$(detect_os)
PM=$(get_package_manager)

# Check if Cursor is already installed
if [[ "$OS" == "macos" ]]; then
  if [[ -d "/Applications/Cursor.app" ]] || command -v cursor >/dev/null 2>&1; then
    log_info "Cursor is already installed"
    exit 0
  fi
else
  # Linux: Check for AppImage or command
  if command -v cursor >/dev/null 2>&1 || [[ -f "$HOME/Applications/cursor/cursor.AppImage" ]]; then
    log_info "Cursor is already installed"
    exit 0
  fi
fi

log_info "Cursor is not installed. Installing..."

if [[ "$OS" == "macos" ]]; then
  install_brew_cask cursor
  log_success "Cursor installed successfully"
else
  # Linux: Install via AppImage
  CURSOR_DIR="$HOME/Applications/cursor"
  CURSOR_APPIMAGE="$CURSOR_DIR/cursor.AppImage"

  # Ensure libfuse2 is installed for AppImage support
  if [[ "$PM" == "apt" ]]; then
    # Ubuntu 24.04+ uses libfuse2t64, older versions use libfuse2
    if apt-cache show libfuse2t64 >/dev/null 2>&1; then
      maybe_sudo apt install -y libfuse2t64
    else
      maybe_sudo apt install -y libfuse2
    fi
  elif [[ "$PM" == "dnf" ]]; then
    maybe_sudo dnf install -y fuse fuse-libs
  elif [[ "$PM" == "pacman" ]]; then
    maybe_sudo pacman -S --noconfirm fuse2
  fi

  # Create directory and download AppImage
  run_cmd mkdir -p "$CURSOR_DIR"

  log_info "Downloading Cursor AppImage..."
  ARCH=$(detect_arch)
  if [[ "$ARCH" == "arm64" ]]; then
    DOWNLOAD_URL="https://downloader.cursor.sh/linux/appImage/arm64"
  else
    DOWNLOAD_URL="https://downloader.cursor.sh/linux/appImage/x64"
  fi

  run_cmd wget -O "$CURSOR_APPIMAGE" "$DOWNLOAD_URL"
  run_cmd chmod +x "$CURSOR_APPIMAGE"

  # Create symlink in ~/.local/bin
  run_cmd mkdir -p "$HOME/.local/bin"
  run_cmd ln -sf "$CURSOR_APPIMAGE" "$HOME/.local/bin/cursor"

  # Create desktop entry
  DESKTOP_DIR="$HOME/.local/share/applications"
  run_cmd mkdir -p "$DESKTOP_DIR"

  # Extract icon from AppImage if possible
  ICON_PATH="$CURSOR_DIR/cursor.png"
  if [[ ! -f "$ICON_PATH" ]]; then
    # Try to extract icon, fall back to generic icon
    cd "$CURSOR_DIR"
    if "$CURSOR_APPIMAGE" --appimage-extract cursor.png >/dev/null 2>&1; then
      mv squashfs-root/cursor.png "$ICON_PATH" 2>/dev/null || true
      rm -rf squashfs-root 2>/dev/null || true
    elif "$CURSOR_APPIMAGE" --appimage-extract "*.png" >/dev/null 2>&1; then
      find squashfs-root -name "*.png" -exec cp {} "$ICON_PATH" \; 2>/dev/null || true
      rm -rf squashfs-root 2>/dev/null || true
    fi
    cd - >/dev/null
  fi

  cat > "$DESKTOP_DIR/cursor.desktop" << EOF
[Desktop Entry]
Name=Cursor
Comment=Cursor AI Code Editor
Exec=$CURSOR_APPIMAGE --no-sandbox %F
Icon=$ICON_PATH
Type=Application
Categories=Development;IDE;TextEditor;
StartupWMClass=Cursor
MimeType=text/plain;inode/directory;
EOF

  run_cmd chmod +x "$DESKTOP_DIR/cursor.desktop"

  log_success "Cursor installed successfully"
  log_info "Run 'cursor' from the terminal or find it in your applications menu"
fi
