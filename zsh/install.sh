#!/usr/bin/env sh

set -e

echo "🚀 zsh installation"

if [ -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  printf "zsh-autosuggestions is already installed\n"
else
  git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi

if [ -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions" ]; then
  printf "zsh-completions is already installed\n"
else
  git clone https://github.com/zsh-users/zsh-completions.git "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions"
fi

ln -sf "${PWD}/zsh/.zshrc" "${HOME}/.zshrc"
