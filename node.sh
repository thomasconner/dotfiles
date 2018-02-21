#!/bin/bash

# This script must run after the OS-specific scripts because it depends on Nodenv.

# Get script directory (allows running from outside `dotfiles` dir)
DIR="$( cd "$(dirname "$0")" ; pwd -P )"

source "$DIR/helpers.sh"

# Get script directory (allows running from outside `dotfiles` dir)
DIR="$( cd "$(dirname "$0")" ; pwd -P )"

message "Setting up Node..."

message "  Symlinking default packages file..."
ln -sf "$DIR/npm-default-packages" "$(nodenv root)/default-packages"

# 1. Get list of Node versions
# 2. Filter to only get normal Node versions, like "  9.5.0"
# 3. Take last line of output which will be latest version
# 4. Remove the leading spaces
LATEST_NODE_VERSION=$(nodenv install --list | grep '^\s\s[0-9]' | tail -1 | xargs)
if [[ -n "$LATEST_NODE_VERSION" ]]; then
    message "  Installing Node $LATEST_NODE_VERSION and default npm packages..."
    # Feed "yes" to the command in case it prompts to reinstall
    yes | nodenv install "$LATEST_NODE_VERSION" &> /dev/null
    nodenv global "$LATEST_NODE_VERSION" &> /dev/null
    message "  Done installing Node and default npm packages."
else
    warn "  could not get latest Node version; installation failed"
fi

message "Done setting up Node."
