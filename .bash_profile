#!/usr/bin/env bash

# Clear out path to prevent reordering in Tmux (https://superuser.com/a/583502/201849)
if [ -f /etc/profile ] && [[ "$OSTYPE" == darwin* ]]; then
  PATH=""
  source /etc/profile
fi

# shellcheck source=.exports
source ~/.exports

# shellcheck source=.bashrc
source ~/.bashrc

# shellcheck source=.aliases
source ~/.aliases

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
fi

# Initialize Nodenv
eval "$(nodenv init -)"

# Temporary override to get rid of mysterious NODE_ENV=production
unset NODE_ENV

# Temporary override to get rid of mysterious DOCKER_HOST on WSL
unset DOCKER_HOST

# Initialize broot
source "${XDG_CONFIG_HOME:-$HOME/.config}"/org.dystroy.broot/launcher/bash/br

# If in an interactive session, Tmux is installed, and not in a Tmux pane
if [ -t 1 ] && command -v tmux > /dev/null && ! [ -v TMUX ]; then
  tmux attach || tmux new
fi
