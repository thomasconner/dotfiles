#!/usr/bin/env bash

set -e

echo "zsh installation"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

# Install zsh plugins
ensure_git_repo "https://github.com/zsh-users/zsh-autosuggestions" "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
ensure_git_repo "https://github.com/zsh-users/zsh-completions.git" "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions"

ln -sf "${PWD}/zsh/.zshrc" "${HOME}/.zshrc"
