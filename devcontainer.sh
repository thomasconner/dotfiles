#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Run zsh install script directly - bypasses "already installed" detection
# since devcontainer base images often have partial zsh setups (Oh My Zsh
# pre-installed but missing Pure prompt, plugins, and our config)
exec bash components/zsh/install.sh
