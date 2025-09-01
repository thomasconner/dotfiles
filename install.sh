#!/usr/bin/env bash

set -e

###
# Installation
###
./fonts/install.sh
./git/install.sh
./node/install.sh
./ruby/install.sh
./shell/install.sh
./tmux/install.sh
./warp/install.sh
./zsh/install.sh

###
# Manual notifications
###
echo "🚀 Manual installation/updates"
echo "Omz: omz update"
echo ""
