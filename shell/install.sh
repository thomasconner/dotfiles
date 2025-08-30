#!/usr/bin/env bash

set -e

echo "Shell installation"

# Ensure curl is installed
if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not installed. Installing..."
  sudo apt update && sudo apt install -y curl
fi

if [ -d "${HOME}/.oh-my-zsh" ]; then
  printf "oh-my-zsh is already installed\n"
else
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Ensure git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed. Installing..."
  sudo apt update && sudo apt install -y git
fi

if [ -d "${HOME}/.zsh/pure" ]; then
  printf "pure prompt is already installed, updating\n"
  git -C "${HOME}/.zsh/pure" pull --ff-only
else
  git clone https://github.com/sindresorhus/pure.git "${HOME}/.zsh/pure"
fi

ln -sf "${PWD}/shell/aliases.zsh" "${HOME}/.oh-my-zsh/custom/aliases.zsh"
ln -sf "${PWD}/shell/exports.zsh" "${HOME}/.oh-my-zsh/custom/exports.zsh"
ln -sf "${PWD}/shell/path.zsh" "${HOME}/.oh-my-zsh/custom/path.zsh"
