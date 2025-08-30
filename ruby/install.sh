#!/usr/bin/env bash

set -e

echo "Ruby configuration"

if command -v ruby >/dev/null 2>&1; then
    echo "Ruby is installed: $(ruby -v)"
else
  if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed. Installing..."
    sudo apt update && sudo apt install -y git
  fi

  if [ -d "${HOME}/.rbenv" ]; then
    printf "rbenv is already installed, updating\n"
    git -C "${HOME}/.rbenv" pull --ff-only
  else
    git clone https://github.com/rbenv/rbenv.git "${HOME}/.rbenv"
  fi

  eval "$($HOME/.rbenv/bin/rbenv init - zsh)"

  if  [ -d "${HOME}/.rbenv/plugins/ruby-build" ]; then
    printf "ruby-build is already installed\n"
    git -C "${HOME}/.rbenv/plugins/ruby-build" pull --ff-only
  else
    sudo apt update && sudo apt install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev
    git clone https://github.com/rbenv/ruby-build.git "${HOME}/.rbenv/plugins/ruby-build"
  fi
fi

if command -v rbenv >/dev/null 2>&1; then
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
