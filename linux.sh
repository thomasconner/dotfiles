#!/usr/bin/env bash

DIR="$(dirname "$(realpath "$0")")"

# shellcheck source=./helpers.sh
source "$DIR/helpers.sh"

# shellcheck disable=SC2119
request-sudo

message "  %s" "setting up Linux..."

message "    %s" "installing essential tools..."
if command -v apt-get > /dev/null; then
    sudo apt-get update > /dev/null
    sudo apt-get install --yes build-essential curl file git > /dev/null
else
    error "could not find a supported package manager; skipping install"
fi
message "    %s" "done installing essential tools."

if ! command -v brew &> /dev/null; then
    message "    %s" "installing Linuxbrew..."
    set +eu
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)" || true
    set -eu
    message "    %s" "done installing Linuxbrew."
fi

message "  %s" "done setting up Linux."
