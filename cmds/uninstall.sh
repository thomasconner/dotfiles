#!/usr/bin/env bash

# ctdev uninstall - Remove dotfiles components

# ============================================================================
# Uninstall functions
# ============================================================================

uninstall_zsh() {
    log_step "Uninstalling Zsh configuration"

    # Remove Oh My Zsh custom symlinks
    local custom_dir="$HOME/.oh-my-zsh/custom"
    if [[ -d "$custom_dir" ]]; then
        log_info "Removing shell config symlinks..."
        run_cmd rm -f "$custom_dir/aliases.zsh"
        run_cmd rm -f "$custom_dir/exports.zsh"
        run_cmd rm -f "$custom_dir/path.zsh"
        run_cmd rm -f "$custom_dir/exports.local.zsh"
    fi

    # Remove Pure prompt
    if [[ -d "$HOME/.zsh/pure" ]]; then
        log_info "Removing Pure prompt..."
        run_cmd rm -rf "$HOME/.zsh/pure"
    fi

    # Remove zsh plugins
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        log_info "Removing zsh-autosuggestions..."
        run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    fi

    if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]]; then
        log_info "Removing zsh-completions..."
        run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
    fi

    # Remove .zshrc symlink
    if [[ -L "$HOME/.zshrc" ]]; then
        log_info "Removing .zshrc symlink..."
        run_cmd rm -f "$HOME/.zshrc"
    fi

    log_success "Zsh configuration removed"
    log_info "Note: Oh My Zsh itself was not removed. Run 'uninstall_oh_my_zsh' to remove it."
}

uninstall_git() {
    log_step "Uninstalling Git configuration"

    if [[ -L "$HOME/.gitconfig" ]]; then
        log_info "Removing .gitconfig symlink..."
        run_cmd rm -f "$HOME/.gitconfig"
    fi

    if [[ -L "$HOME/.gitignore" ]]; then
        log_info "Removing .gitignore symlink..."
        run_cmd rm -f "$HOME/.gitignore"
    fi

    log_success "Git configuration removed"
    log_info "Note: .gitconfig.local was preserved (contains your personal settings)"
}

uninstall_node() {
    log_step "Uninstalling Node.js (nodenv)"

    if [[ -d "$HOME/.nodenv" ]]; then
        log_info "Removing nodenv..."
        run_cmd rm -rf "$HOME/.nodenv"
        log_success "nodenv removed"
    else
        log_info "nodenv not installed"
    fi

    log_info "Note: Remove nodenv lines from your shell profile manually"
}

uninstall_ruby() {
    log_step "Uninstalling Ruby (rbenv)"

    if [[ -d "$HOME/.rbenv" ]]; then
        log_info "Removing rbenv..."
        run_cmd rm -rf "$HOME/.rbenv"
        log_success "rbenv removed"
    else
        log_info "rbenv not installed"
    fi

    log_info "Note: Remove rbenv lines from your shell profile manually"
}

uninstall_fonts() {
    log_step "Uninstalling Nerd Fonts"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        log_info "Removing Nerd Fonts from ~/Library/Fonts..."
        run_cmd rm -f ~/Library/Fonts/*Nerd*
    else
        log_info "Removing Nerd Fonts from ~/.local/share/fonts..."
        run_cmd rm -rf ~/.local/share/fonts/*Nerd*
    fi

    log_success "Nerd Fonts removed"
}

uninstall_cli() {
    log_step "Uninstalling CLI tools"

    local os
    os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        log_info "On macOS, CLI tools were installed via Homebrew."
        log_info "To uninstall, run:"
        echo "  brew uninstall jq gh kubectl doctl helm age sops terraform btop"
    else
        log_info "CLI tools were installed via direct download or package manager."
        log_info "Manual removal may be required for some tools."

        # Remove tools installed to /usr/local/bin
        local tools=("kubectl" "doctl" "helm" "age" "sops")
        for tool in "${tools[@]}"; do
            if [[ -f "/usr/local/bin/$tool" ]]; then
                log_info "Removing $tool..."
                run_cmd maybe_sudo rm -f "/usr/local/bin/$tool"
            fi
        done
    fi

    log_success "CLI tools uninstall complete"
}

uninstall_apps() {
    log_step "Uninstalling Applications"

    local os
    os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        log_info "On macOS, applications were installed via Homebrew Cask."
        log_info "To uninstall, run:"
        echo "  brew uninstall --cask google-chrome slack visual-studio-code"
    else
        log_info "Applications were installed via system packages."
        log_info "Use your package manager to remove them."
    fi

    log_success "Apps uninstall guidance provided"
}

# ============================================================================
# Main command
# ============================================================================

cmd_uninstall() {
    local components=("$@")

    # Require at least one component
    if [[ ${#components[@]} -eq 0 ]]; then
        log_error "At least one component must be specified"
        echo ""
        echo "Usage: ctdev uninstall <component...>"
        echo ""
        echo "Available components:"
        list_components | while read -r name; do
            echo "  $name"
        done
        return 1
    fi

    # Validate specified components
    if ! validate_components "${components[@]}"; then
        return 1
    fi

    log_step "Uninstalling components: ${components[*]}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    echo

    for component in "${components[@]}"; do
        case "$component" in
            zsh)   uninstall_zsh ;;
            git)   uninstall_git ;;
            node)  uninstall_node ;;
            ruby)  uninstall_ruby ;;
            fonts) uninstall_fonts ;;
            cli)   uninstall_cli ;;
            apps)  uninstall_apps ;;
            *)
                log_warning "No uninstall function for: $component"
                ;;
        esac
        echo
    done

    log_step "Uninstall complete"
    log_info "You may need to restart your shell for changes to take effect"
}
