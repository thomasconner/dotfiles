#!/usr/bin/env sh

set -e

###
# Installation
###
./node/install.sh
./shell/install.sh
./zsh/install.sh
./git/install.sh


###
# Manual notifications
###
echo "🚀 Manual installation/updates"
echo "Omz:     omz update"
echo ""
