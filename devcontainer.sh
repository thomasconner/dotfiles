#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Force install zsh - devcontainer base images often have partial zsh setups
# (Oh My Zsh pre-installed but missing Pure prompt, plugins, and our config)
export FORCE=true
exec bash components/zsh/install.sh
