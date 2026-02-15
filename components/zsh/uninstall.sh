#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Uninstalling zsh configuration..."

custom_dir="$HOME/.oh-my-zsh/custom"
if [[ -d "$custom_dir" ]]; then
    run_cmd rm -f "$custom_dir/aliases.zsh"
    run_cmd rm -f "$custom_dir/exports.zsh"
    run_cmd rm -f "$custom_dir/path.zsh"
    run_cmd rm -f "$custom_dir/exports.local.zsh"
fi

[[ -d "$HOME/.zsh/pure" ]] && run_cmd rm -rf "$HOME/.zsh/pure"
[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] && run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]] && run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
[[ -L "$HOME/.zfunc/_ctdev" ]] && run_cmd rm -f "$HOME/.zfunc/_ctdev"
[[ -L "$HOME/.zshrc" ]] && run_cmd rm -f "$HOME/.zshrc"

log_info "Oh My Zsh kept. Run 'uninstall_oh_my_zsh' to remove it."
