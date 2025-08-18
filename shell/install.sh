#!/usr/bin/env sh

set -e

echo "🚀 Shell installation"

if [ -d "${HOME}/.oh-my-zsh" ]; then
  printf "oh-my-zsh is already installed\n"
else
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [ -d "${HOME}/.zsh/pure" ]; then
  printf "pure prompt is already installed\n"
else
  git clone https://github.com/sindresorhus/pure.git "${HOME}/.zsh/pure"
fi

ln -sf "${PWD}/shell/aliases.zsh" "${HOME}/.oh-my-zsh/custom/aliases.zsh"
ln -sf "${PWD}/shell/exports.zsh" "${HOME}/.oh-my-zsh/custom/exports.zsh"
ln -sf "${PWD}/shell/path.zsh" "${HOME}/.oh-my-zsh/custom/path.zsh"
