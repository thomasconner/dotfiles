#!/usr/bin/env bash

set -e

echo "Shell installation"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

# Ensure curl is installed
ensure_curl_installed

if [ -d "${HOME}/.oh-my-zsh" ]; then
  printf "oh-my-zsh is already installed\n"
else
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Ensure Pure prompt is installed/updated
ensure_git_repo "https://github.com/sindresorhus/pure.git" "${HOME}/.zsh/pure"

ln -sf "${PWD}/shell/aliases.zsh" "${HOME}/.oh-my-zsh/custom/aliases.zsh"
ln -sf "${PWD}/shell/exports.zsh" "${HOME}/.oh-my-zsh/custom/exports.zsh"
ln -sf "${PWD}/shell/path.zsh" "${HOME}/.oh-my-zsh/custom/path.zsh"
