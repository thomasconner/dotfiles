#!/usr/bin/env bash

set -e

###
# Installation
###
./apps/install.sh
./fonts/install.sh
./git/install.sh
./node/install.sh
./ruby/install.sh
./zsh/install.sh

###
# Manual notifications
###
echo "🚀 Manual installation/updates"
echo "Omz: omz update"
echo ""
