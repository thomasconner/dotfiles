#!/usr/bin/env bash

set -e

echo "🚀 Ruby configuration"

# Ensure git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is not installed. Installing..."
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
  sudo apt update && apt install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev
  git clone https://github.com/rbenv/ruby-build.git "${HOME}/.rbenv/plugins/ruby-build"
fi

RUBY_VERSION=3.4.5
echo "Installing ${RUBY_VERSION} version of ruby"
rbenv install --skip-existing "${RUBY_VERSION}"
rbenv global "${RUBY_VERSION}"

echo "Installing ruby gems"
RUBY_GEMS=(colorls)
for gem in "${RUBY_GEMS[@]}"; do
  printf "installing %s\n" "${gem}"
  gem install "${gem}"
done
