#!/usr/bin/env sh

set -e

echo "🚀 Fonts installation"

# Ensure git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is not installed. Installing..."
  sudo apt update && sudo apt install -y git
fi

if [ -d "${HOME}/.nerd-fonts" ]; then
  printf "✅ nerd-fonts already installed, updating...\n"
  git -C "${HOME}/.nerd-fonts" pull --ff-only
else
  printf "⬇️ Cloning nerd-fonts repository...\n"
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git "${HOME}/.nerd-fonts"
fi

bash "${HOME}/.nerd-fonts/install.sh"
