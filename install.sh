#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for ctdev dotfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/thomasconner/dotfiles/main/install.sh | bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="https://github.com/thomasconner/dotfiles.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Check for git
if ! command -v git >/dev/null 2>&1; then
    error "Git is required. Please install git first."
fi

echo
echo "  ┌─────────────────────────────────────┐"
echo "  │  ctdev dotfiles installer           │"
echo "  └─────────────────────────────────────┘"
echo

# Clone or update repo
if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles directory exists at $DOTFILES_DIR"
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        info "Updating existing installation..."
        cd "$DOTFILES_DIR"
        git pull --rebase || warn "Could not update, continuing with existing version"
    else
        error "$DOTFILES_DIR exists but is not a git repo. Please remove it or set DOTFILES_DIR."
    fi
else
    info "Cloning dotfiles to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# Run setup
info "Running ctdev setup..."
"$DOTFILES_DIR/ctdev" setup

success "ctdev is now installed!"
echo
echo "  Next steps:"
echo "    1. Restart your terminal (or run: source ~/.zshrc)"
echo "    2. Run: ctdev install"
echo
echo "  Or install specific components:"
echo "    ctdev install zsh git    # Shell and git config"
echo "    ctdev install cli        # CLI tools"
echo "    ctdev list               # See all components"
echo
echo "  Run 'ctdev --help' for more options."
echo
