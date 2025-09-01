#!/usr/bin/env bash

set -e

echo "Node configuration"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

if command -v node >/dev/null 2>&1; then
    echo "Node.js is installed: $(node -v)"
else
  ensure_git_repo "https://github.com/nodenv/nodenv.git" "${HOME}/.nodenv"
  ensure_git_repo "https://github.com/nodenv/node-build.git" "${HOME}/.nodenv/plugins/node-build"

  eval "$($HOME/.nodenv/bin/nodenv init -)"
fi

if command -v nodenv >/dev/null 2>&1; then
  NODE_VERSION=24.6.0
  echo "Ensuring Node.js ${NODE_VERSION} with nodenv"

  # Install if missing
  if ! nodenv versions --bare | grep -qx "${NODE_VERSION}"; then
    echo "Installing Node.js ${NODE_VERSION}..."
    nodenv install "${NODE_VERSION}"
  else
    echo "Node.js ${NODE_VERSION} already installed"
  fi

  # Set as global if not already
  CURRENT_GLOBAL=$(nodenv global)
  if [ "${CURRENT_GLOBAL}" != "${NODE_VERSION}" ]; then
    echo "Setting Node.js ${NODE_VERSION} as global version"
    nodenv global "${NODE_VERSION}"
  else
    echo "Node.js ${NODE_VERSION} is already the global version"
  fi

  # Rehash to refresh shims
  nodenv rehash

  # Show installed version
  echo "Using Node.js version: $(node -v)"
fi

NODE_PACKAGES=(@anthropic-ai/claude-code ngrok)
for pkg in "${NODE_PACKAGES[@]}"; do
  if npm list -g --depth=0 | grep -q " ${pkg}@"; then
    printf "Updating %s\n" "${pkg}"
    npm update -g "${pkg}"
  else
    printf "Installing %s\n" "${pkg}"
    npm install -g "${pkg}"
  fi
done
