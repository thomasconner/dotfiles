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

uninstall_macos() {
    log_step "Resetting macOS defaults"

    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_info "Not on macOS, skipping"
        return
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would reset Dock settings to Apple defaults"
        log_info "[DRY-RUN] Would reset Finder settings to Apple defaults"
        log_info "[DRY-RUN] Would reset Keyboard settings to Apple defaults"
        log_info "[DRY-RUN] Would reset Dialog settings to Apple defaults"
        log_info "[DRY-RUN] Would reset Security settings to Apple defaults"
        log_info "[DRY-RUN] Would restart Dock and Finder"
        log_success "macOS defaults would be reset"
        return
    fi

    log_info "Resetting Dock settings..."
    defaults delete com.apple.dock autohide-delay 2>/dev/null || true
    defaults delete com.apple.dock autohide-time-modifier 2>/dev/null || true
    defaults delete com.apple.dock launchanim 2>/dev/null || true
    defaults delete com.apple.dock show-recents 2>/dev/null || true
    defaults delete com.apple.dock minimize-to-application 2>/dev/null || true

    log_info "Resetting Finder settings..."
    defaults delete com.apple.finder AppleShowAllFiles 2>/dev/null || true
    defaults delete NSGlobalDomain AppleShowAllExtensions 2>/dev/null || true
    defaults delete com.apple.finder ShowPathbar 2>/dev/null || true
    defaults delete com.apple.finder ShowStatusBar 2>/dev/null || true
    defaults delete com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null || true
    defaults delete com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null || true
    defaults delete com.apple.finder FXDefaultSearchScope 2>/dev/null || true
    defaults delete com.apple.finder FXPreferredViewStyle 2>/dev/null || true
    defaults delete com.apple.finder QuitMenuItem 2>/dev/null || true

    log_info "Resetting Keyboard settings..."
    defaults delete NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticDashSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticSpellingCorrectionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticCapitalizationEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain KeyRepeat 2>/dev/null || true
    defaults delete NSGlobalDomain InitialKeyRepeat 2>/dev/null || true
    defaults delete NSGlobalDomain AppleKeyboardUIMode 2>/dev/null || true

    log_info "Resetting Dialog settings..."
    defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode 2>/dev/null || true
    defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 2>/dev/null || true
    defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint 2>/dev/null || true
    defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint2 2>/dev/null || true

    log_info "Resetting Security settings..."
    defaults delete com.apple.screensaver askForPassword 2>/dev/null || true
    defaults delete com.apple.screensaver askForPasswordDelay 2>/dev/null || true

    log_info "Applying changes..."
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true

    log_success "macOS defaults reset to Apple defaults"
    log_info "Note: Some settings may require a logout/restart to take full effect"
}

uninstall_claude() {
    log_step "Uninstalling Claude Code configuration"

    local claude_dir="$HOME/.claude"

    if [[ -L "$claude_dir/CLAUDE.md" ]]; then
        log_info "Removing CLAUDE.md symlink..."
        run_cmd rm -f "$claude_dir/CLAUDE.md"
    fi

    if [[ -L "$claude_dir/settings.json" ]]; then
        log_info "Removing settings.json symlink..."
        run_cmd rm -f "$claude_dir/settings.json"
    fi

    if [[ -L "$claude_dir/settings.local.json" ]]; then
        log_info "Removing settings.local.json symlink..."
        run_cmd rm -f "$claude_dir/settings.local.json"
    fi

    log_success "Claude Code configuration removed"
    log_info "Note: ~/.claude directory preserved (used by Claude Code)"
}

# ============================================================================
# Main command
# ============================================================================

cmd_uninstall() {
    local components=("$@")

    # If no components specified, uninstall all (with confirmation)
    if [[ ${#components[@]} -eq 0 ]]; then
        local installed=()
        while IFS= read -r comp; do
            installed+=("$comp")
        done < <(list_installed_components)

        if [[ ${#installed[@]} -eq 0 ]]; then
            log_info "No components are currently installed"
            return 0
        fi

        log_warning "This will uninstall all ${#installed[@]} components:"
        for comp in "${installed[@]}"; do
            echo "  - $comp"
        done
        echo

        if [[ -t 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
            printf "Are you sure? [y/N] "
            if ! read -r -t 30 answer || [[ ! "$answer" =~ ^[Yy]$ ]]; then
                log_info "Aborted"
                return 0
            fi
        fi

        # Uninstall in reverse order of DEFAULT_INSTALL_ORDER
        local reverse_order
        reverse_order=$(echo "$DEFAULT_INSTALL_ORDER" | tr ' ' '\n' | tac | tr '\n' ' ')
        for comp in $reverse_order; do
            if [[ " ${installed[*]} " == *" $comp "* ]]; then
                components+=("$comp")
            fi
        done
        # Add macos if installed (not in DEFAULT_INSTALL_ORDER)
        if is_component_installed "macos"; then
            components=("macos" "${components[@]}")
        fi
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
            claude) uninstall_claude ;;
            cli)   uninstall_cli ;;
            apps)  uninstall_apps ;;
            macos) uninstall_macos ;;
            *)
                log_warning "No uninstall function for: $component"
                ;;
        esac
        # Remove installation marker
        remove_install_marker "$component"
        echo
    done

    log_step "Uninstall complete"
    log_info "You may need to restart your shell for changes to take effect"
}
