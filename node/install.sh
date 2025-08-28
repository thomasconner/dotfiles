#!/usr/bin/env bash

set -e

echo "🚀 Node configuration"

# Ensure git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is not installed. Installing..."
  sudo apt update && sudo apt install -y git
fi

if [ -d "${HOME}/.nodenv" ]; then
  printf "nodenv is already installed, updating\n"
  git -C "${HOME}/.nodenv" pull --ff-only
else
  git clone https://github.com/nodenv/nodenv.git "${HOME}/.nodenv"
fi

eval "$($HOME/.nodenv/bin/nodenv init -)"

if  [ -d "${HOME}/.nodenv/plugins/node-build" ]; then
  printf "node-build is already installed, updating\n"
  git -C "${HOME}/.nodenv/plugins/node-build" pull --ff-only
else
  git clone https://github.com/nodenv/node-build.git "${HOME}/.nodenv/plugins/node-build"
fi

NODE_VERSION=22.17.1
echo "Installing ${NODE_VERSION} version of node"
nodenv install "${NODE_VERSION}" --skip-existing
nodenv global "${NODE_VERSION}"

# echo "Installing node packages"
NODE_PACKAGES=()
for pkg in "${NODE_PACKAGES[@]}"; do
  printf "installing %s\n" "${pkg}"
  npm install -g "${pkg}"
done
