#!/bin/bash

# Get script directory (allows running from outside `dotfiles` dir)
DIR="$( cd "$(dirname "$0")" || return; pwd -P )"

# shellcheck source=./helpers.sh
source "$DIR/helpers.sh"

message "Setting up apt..."

message "Adding apt repositories..."
curl -s https://updates.signal.org/desktop/apt/keys.asc | request-sudo apt-key add -
echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | request-sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
message "Done adding apt repositories."

# Refresh apt
request-sudo apt-get update
request-sudo apt-get upgrade -y

declare -a apt_packages=(
    # applications
    thunderbird

    # tools
    emacs
    gnupg2
    htop    # System monitoring tool
    httpie
    kdiff3    # Merge tool
    meld    # Comparison tool for version control, files, and directories
    nnn   # Command-line file browser
    jq    # JSON processor
    mosh
    python-pip
    zsh

    # languages
    golang-go
)

message "  %s" "Installing packages..."
for package in "${apt_packages[@]}"; do
    set +e
    # Attempt to install package; log message on success, log warning on failure
    request-sudo apt-get install -y "$package" &> /dev/null && \
        message "    %s" "Installed $package" || \
        warn "    %s" "package $package failed to install"
    set -e
done
message "  %s" "Done installing packages."

message "Done setting up apt."
