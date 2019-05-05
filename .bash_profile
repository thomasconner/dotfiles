#!/usr/bin/env bash

# shellcheck source=.bashrc
source ~/.bashrc

# shellcheck source=.aliases
source ~/.aliases

# shellcheck source=.exports
source ~/.exports

# shellcheck source=.functions
source ~/.functions

# Load file if exists, suppress error if missing
# shellcheck source=/dev/null
source ~/.locals &> /dev/null || true

# Initialize Linuxbrew if it exists
if [ -d /home/linuxbrew/.linuxbrew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if is-wsl; then
  # https://github.com/Microsoft/WSL/issues/352
  umask 022

  # relies on C: drive mounted at root instead of at /mnt
  eval "$(/c/ssh-agent-wsl/ssh-agent-wsl --reuse)" > /dev/null
  alias ssh-agent='/c/ssh-agent-wsl/ssh-agent-wsl'
fi

# Initialize Nodenv
eval "$(nodenv init -)"
