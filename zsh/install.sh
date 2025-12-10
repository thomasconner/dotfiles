#!/usr/bin/env bash

set -euo pipefail

echo "zsh installation"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

OS=$(detect_os)

# Install zsh if not already installed
if ! command -v zsh >/dev/null 2>&1; then
  if [[ "$OS" == "macos" ]]; then
    # macOS comes with zsh pre-installed, but install via brew if missing
    log_info "Installing zsh via Homebrew..."
    ensure_brew_installed
    brew install zsh
  else
    log_info "Installing zsh..."
    install_package zsh
  fi
else
  log_info "zsh is already installed: $(zsh --version)"
fi

# Set zsh as default shell if not already set
if [ "$SHELL" != "$(which zsh)" ]; then
  # Only try to change shell if not root and not in Docker/CI
  if [ "$EUID" -ne 0 ] && [ -t 0 ]; then
    log_info "Setting zsh as default shell..."
    # On macOS, zsh might not be in /etc/shells if installed via brew
    if [[ "$OS" == "macos" ]]; then
      ZSH_PATH=$(which zsh)
      if ! grep -q "$ZSH_PATH" /etc/shells; then
        log_info "Adding $ZSH_PATH to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
      fi
      chsh -s "$ZSH_PATH"
    else
      maybe_sudo chsh -s "$(which zsh)"
    fi
  fi
fi

if [ -d "${HOME}/.oh-my-zsh" ]; then
  printf "oh-my-zsh is already installed\n"
else
  ensure_curl_installed
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Ensure Pure prompt is installed/updated
ensure_git_repo "https://github.com/sindresorhus/pure.git" "${HOME}/.zsh/pure"

# Create symlinks that promptinit expects
# Pure needs prompt_pure_setup and async in fpath
mkdir -p "${HOME}/.zsh/functions"
ln -sf "${HOME}/.zsh/pure/pure.zsh" "${HOME}/.zsh/functions/prompt_pure_setup"
ln -sf "${HOME}/.zsh/pure/async.zsh" "${HOME}/.zsh/functions/async"

log_success "Pure prompt installed at ${HOME}/.zsh/pure"

ln -sf "${SCRIPT_DIR}/../shell/aliases.zsh" "${HOME}/.oh-my-zsh/custom/aliases.zsh"
ln -sf "${SCRIPT_DIR}/../shell/exports.zsh" "${HOME}/.oh-my-zsh/custom/exports.zsh"
ln -sf "${SCRIPT_DIR}/../shell/path.zsh" "${HOME}/.oh-my-zsh/custom/path.zsh"

# Copy exports.local.zsh if it doesn't exist (like .gitconfig.local)
if [ ! -f "${HOME}/.oh-my-zsh/custom/exports.local.zsh" ]; then
  cp "${SCRIPT_DIR}/../shell/exports.local.zsh" "${HOME}/.oh-my-zsh/custom/exports.local.zsh"
  echo "Created ${HOME}/.oh-my-zsh/custom/exports.local.zsh - Please customize it!"
fi

# Install zsh plugins
ensure_git_repo "https://github.com/zsh-users/zsh-autosuggestions" "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
ensure_git_repo "https://github.com/zsh-users/zsh-completions.git" "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions"

ln -sf "${SCRIPT_DIR}/.zshrc" "${HOME}/.zshrc"
