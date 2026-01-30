#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing zsh"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install: zsh, Oh My Zsh, Pure prompt, plugins, shell config symlinks"
    exit 0
fi

if [[ "${FORCE:-false}" != "true" ]] && [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_info "zsh already installed"
    exit 0
fi

OS=$(detect_os)

if ! command -v zsh >/dev/null 2>&1; then
    if [[ "$OS" == "macos" ]]; then
        ensure_brew_installed
        brew install zsh
    elif is_devcontainer; then
        log_error "zsh not installed. Add 'zsh' to your Dockerfile."
        exit 1
    else
        install_package zsh
    fi
else
    log_info "zsh already installed: $(zsh --version)"
fi

if [ "$SHELL" != "$(which zsh)" ]; then
    if is_devcontainer; then
        log_info "Skipping chsh in devcontainer"
    elif [ "$EUID" -ne 0 ] && [ -t 0 ]; then
        log_info "Setting zsh as default shell..."
        if [[ "$OS" == "macos" ]]; then
            ZSH_PATH=$(which zsh)
            if ! grep -q "$ZSH_PATH" /etc/shells; then
                echo "$ZSH_PATH" | sudo tee -a /etc/shells
            fi
            chsh -s "$ZSH_PATH"
        else
            maybe_sudo chsh -s "$(which zsh)"
        fi
    fi
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    log_info "Oh My Zsh already installed"
else
    ensure_curl_installed
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ensure_git_repo "https://github.com/sindresorhus/pure.git" "$HOME/.zsh/pure"

# Pure prompt needs these symlinks in fpath
mkdir -p "$HOME/.zsh/functions"
safe_symlink "$HOME/.zsh/pure/pure.zsh" "$HOME/.zsh/functions/prompt_pure_setup"
safe_symlink "$HOME/.zsh/pure/async.zsh" "$HOME/.zsh/functions/async"

log_success "Pure prompt installed"

safe_symlink "$DOTFILES_ROOT/shell/aliases.zsh" "$HOME/.oh-my-zsh/custom/aliases.zsh"
safe_symlink "$DOTFILES_ROOT/shell/exports.zsh" "$HOME/.oh-my-zsh/custom/exports.zsh"
safe_symlink "$DOTFILES_ROOT/shell/path.zsh" "$HOME/.zsh/path.zsh"

if [ ! -f "$HOME/.oh-my-zsh/custom/exports.local.zsh" ]; then
    run_cmd cp "$DOTFILES_ROOT/shell/exports.local.zsh" "$HOME/.oh-my-zsh/custom/exports.local.zsh"
    log_info "Created exports.local.zsh - customize it!"
fi

ensure_git_repo "https://github.com/zsh-users/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
ensure_git_repo "https://github.com/zsh-users/zsh-completions.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"

safe_symlink "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

log_success "Zsh installation complete"
