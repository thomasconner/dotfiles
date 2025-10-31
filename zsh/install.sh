#!/usr/bin/env bash

set -euo pipefail

echo "zsh installation"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

if [ "$SHELL" != "$(which zsh)" ]; then
  sudo apt update
  sudo apt install -y zsh
  sudo chsh -s "$(which zsh)"
fi

if [ -d "${HOME}/.oh-my-zsh" ]; then
  printf "oh-my-zsh is already installed\n"
else
  ensure_curl_installed
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Ensure Pure prompt is installed/updated
ensure_git_repo "https://github.com/sindresorhus/pure.git" "${HOME}/.zsh/pure"
mkdir -p "${HOME}/.zsh/functions"
ln -sf "${HOME}/.zsh/pure/pure.zsh" "${HOME}/.zsh/functions/prompt_pure_setup"
ln -sf "${HOME}/.zsh/pure/async.zsh" "${HOME}/.zsh/functions/async"

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
