#!/usr/bin/env sh

set -e

echo "🚀 zsh installation"

# Ensure git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is not installed. Installing..."
  sudo apt update && sudo apt install -y git
fi


if [ -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  printf "zsh-autosuggestions is already installed, updating\n"
  git -C "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" pull --ff-only
else
  git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi

if [ -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions" ]; then
  printf "zsh-completions is already installed, updating\n"
  git -C "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions" pull --ff-only
else
  git clone https://github.com/zsh-users/zsh-completions.git "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions"
fi

ln -sf "${PWD}/zsh/.zshrc" "${HOME}/.zshrc"
