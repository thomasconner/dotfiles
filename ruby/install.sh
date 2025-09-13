#!/usr/bin/env bash

set -e

echo "Ruby configuration"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

if command -v ruby >/dev/null 2>&1; then
    echo "Ruby is installed: $(ruby -v)"
else
  ensure_git_repo "https://github.com/rbenv/rbenv.git" "${HOME}/.rbenv"
  ensure_git_repo "https://github.com/rbenv/ruby-build.git" "${HOME}/.rbenv/plugins/ruby-build"

  if [ -n "$ZSH_VERSION" ]; then
    eval "$("${HOME}/.rbenv/bin/rbenv" init - zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$("${HOME}/.rbenv/bin/rbenv" init - bash)"
  else
    echo "Unknown shell, please add rbenv to your shell configuration manually."
  fi
fi

if command -v rbenv >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc

  RUBY_VERSION=3.4.5
  echo "Ensuring Ruby ${RUBY_VERSION} with rbenv"

  # Install if missing (ruby-build plugin provides 'install')
  if ! rbenv versions --bare | grep -qx "${RUBY_VERSION}"; then
    echo "Installing Ruby ${RUBY_VERSION}..."
    rbenv install "${RUBY_VERSION}"
  else
    echo "Ruby ${RUBY_VERSION} already installed"
  fi

  # Set as global if not already
  CURRENT_GLOBAL="$(rbenv global)"
  if [ "${CURRENT_GLOBAL}" != "${RUBY_VERSION}" ]; then
    echo "Setting Ruby ${RUBY_VERSION} as global version"
    rbenv global "${RUBY_VERSION}"
  else
    echo "Ruby ${RUBY_VERSION} is already the global version"
  fi

  # Refresh shims
  rbenv rehash

  # Show active versions
  echo "Ruby: $(ruby -v)"
  echo "Gem:  $(gem --version)"
fi

RUBY_GEMS=(colorls)
for gem in "${RUBY_GEMS[@]}"; do
  printf "Checking %s...\n" "${gem}"

  if gem list -i "${gem}" > /dev/null 2>&1; then
    printf "Updating %s\n" "${gem}"
    gem update "${gem}"
  else
    printf "⬇Installing %s\n" "${gem}"
    gem install "${gem}"
  fi
done
