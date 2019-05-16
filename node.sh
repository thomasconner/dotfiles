#!/usr/bin/env bash

# This script must run after the OS-specific scripts because it depends on Nodenv.

DIR="$(dirname "$(realpath "$0")")"

# shellcheck source=./helpers.sh
source "$DIR/helpers.sh"

message "setting up Node..."

message "  %s" "copying default packages file..."
cp "$DIR/npm-default-packages" "$(nodenv root)/default-packages" &> /dev/null || true

# 1. Get list of Node versions
# 2. Filter to only get normal Node versions, like "  9.5.0"
# 3. Take last line of output which will be latest version
# 4. Remove the leading spaces
latest_node_version="$(nodenv install --list | grep -E '^\s\s[0-9\.]+$' | tail -1 | xargs)"
if [ -n "$latest_node_version" ]; then
    message "  %s" "installing Node $latest_node_version and default npm packages..."
    nodenv install --force "$latest_node_version" &> /dev/null || true
    nodenv global "$latest_node_version" || true
    eval "$(nodenv init -)"
    message "  %s" "done installing Node and default npm packages."
else
    warn "could not get latest Node version; installation failed"
fi

message "  %s" "initializing npm-merge-driver..."
if command -v npx > /dev/null; then
  npx npm-merge-driver install --global > /dev/null
  message "  %s" "done initializing npm-merge-driver."
else
  warn "npx not found, could not initialize npm-merge-driver"
fi

message "done setting up Node."
