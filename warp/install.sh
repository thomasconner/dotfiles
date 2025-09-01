#!/usr/bin/env bash

set -e

echo "warp-terminal installation"

if dpkg -s warp-terminal >/dev/null 2>&1; then
  echo "warp-terminal is already installed. Updating..."
  sudo apt update
  sudo apt install --only-upgrade warp-terminal -y
else
  echo "warp-terminal not found. Installing..."
  sudo apt-get install wget gpg
  wget -qO- https://releases.warp.dev/linux/keys/warp.asc | gpg --dearmor > warpdotdev.gpg
  sudo install -D -o root -g root -m 644 warpdotdev.gpg /etc/apt/keyrings/warpdotdev.gpg
  sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/warpdotdev.gpg] https://releases.warp.dev/linux/deb stable main" > /etc/apt/sources.list.d/warpdotdev.list'
  rm warpdotdev.gpg
  sudo apt update
  sudo apt install warp-terminal
fi
