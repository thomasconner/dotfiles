#!/usr/bin/env sh

set -e

echo "🚀 Node configuration"

if [ -d "${HOME}/.nodenv" ]; then
  printf "nodenv is already installed\n"
else
  git clone https://github.com/nodenv/nodenv.git "${HOME}/.nodenv"
fi

eval "$($HOME/.nodenv/bin/nodenv init -)"

if  [ -d "${HOME}/.nodenv/plugins/node-build" ]; then
  printf "node-build is already installed\n"
else
  git clone https://github.com/nodenv/node-build.git "${HOME}/.nodenv/plugins/node-build"
fi

# The version of node mainly used
ACTIVE_NODE_VERSION=22.17.1

echo "Installing ${ACTIVE_NODE_VERSION} version of node"
nodenv install "${ACTIVE_NODE_VERSION}" --skip-existing

# echo "Installing node packages"
# NODE_PACKAGES=()
# for pkg in "${NODE_PACKAGES[@]}"; do printf "installing %s\n" "${pkg}" && npm install -g "${pkg}"; done
