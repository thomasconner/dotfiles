#!/usr/bin/env bash

uninstall_zsh() {
    log_step "Uninstalling zsh configuration"

    local custom_dir="$HOME/.oh-my-zsh/custom"
    if [[ -d "$custom_dir" ]]; then
        log_info "Removing shell config symlinks..."
        run_cmd rm -f "$custom_dir/aliases.zsh"
        run_cmd rm -f "$custom_dir/exports.zsh"
        run_cmd rm -f "$custom_dir/path.zsh"
        run_cmd rm -f "$custom_dir/exports.local.zsh"
    fi

    [[ -d "$HOME/.zsh/pure" ]] && run_cmd rm -rf "$HOME/.zsh/pure"
    [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] && run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]] && run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
    [[ -L "$HOME/.zshrc" ]] && run_cmd rm -f "$HOME/.zshrc"

    log_success "Zsh configuration removed"
    log_info "Oh My Zsh kept. Run 'uninstall_oh_my_zsh' to remove it."
}

uninstall_git() {
    log_step "Uninstalling git configuration"

    [[ -L "$HOME/.gitconfig" ]] && run_cmd rm -f "$HOME/.gitconfig"
    [[ -L "$HOME/.gitignore" ]] && run_cmd rm -f "$HOME/.gitignore"

    log_success "Git configuration removed"
    log_info ".gitconfig.local preserved"
}

uninstall_node() {
    log_step "Uninstalling Node.js (nodenv)"

    if [[ -d "$HOME/.nodenv" ]]; then
        run_cmd rm -rf "$HOME/.nodenv"
        log_success "nodenv removed"
    else
        log_info "nodenv not installed"
    fi
}

uninstall_ruby() {
    log_step "Uninstalling Ruby (rbenv)"

    if [[ -d "$HOME/.rbenv" ]]; then
        run_cmd rm -rf "$HOME/.rbenv"
        log_success "rbenv removed"
    else
        log_info "rbenv not installed"
    fi
}

uninstall_fonts() {
    log_step "Uninstalling Nerd Fonts"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        run_cmd rm -f ~/Library/Fonts/*Nerd*
    else
        run_cmd rm -rf ~/.local/share/fonts/*Nerd*
    fi

    log_success "Nerd Fonts removed"
}

uninstall_cli() {
    log_step "Uninstalling CLI tools"

    local os
    os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        log_info "CLI tools installed via Homebrew. To uninstall:"
        echo "  brew uninstall jq gh kubectl doctl helm age sops terraform btop"
    else
        local tools=("kubectl" "doctl" "helm" "age" "sops")
        for tool in "${tools[@]}"; do
            [[ -f "/usr/local/bin/$tool" ]] && run_cmd maybe_sudo rm -f "/usr/local/bin/$tool"
        done
    fi

    log_success "CLI tools uninstall complete"
}

uninstall_apps() {
    log_step "Uninstalling applications"

    local os
    os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        log_info "Apps installed via Homebrew Cask. To uninstall:"
        echo "  brew uninstall --cask google-chrome slack visual-studio-code"
    else
        log_info "Use your package manager to remove apps."
    fi
}

uninstall_macos() {
    log_step "Resetting macOS defaults"

    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_info "Not on macOS, skipping"
        return
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would reset Dock, Finder, Keyboard, Dialog, Security settings"
        return
    fi

    defaults delete com.apple.dock autohide-delay 2>/dev/null || true
    defaults delete com.apple.dock autohide-time-modifier 2>/dev/null || true
    defaults delete com.apple.dock launchanim 2>/dev/null || true
    defaults delete com.apple.dock show-recents 2>/dev/null || true
    defaults delete com.apple.dock minimize-to-application 2>/dev/null || true

    defaults delete com.apple.finder AppleShowAllFiles 2>/dev/null || true
    defaults delete NSGlobalDomain AppleShowAllExtensions 2>/dev/null || true
    defaults delete com.apple.finder ShowPathbar 2>/dev/null || true
    defaults delete com.apple.finder ShowStatusBar 2>/dev/null || true
    defaults delete com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null || true
    defaults delete com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null || true
    defaults delete com.apple.finder FXDefaultSearchScope 2>/dev/null || true
    defaults delete com.apple.finder FXPreferredViewStyle 2>/dev/null || true
    defaults delete com.apple.finder QuitMenuItem 2>/dev/null || true

    defaults delete NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticDashSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticSpellingCorrectionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticCapitalizationEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain KeyRepeat 2>/dev/null || true
    defaults delete NSGlobalDomain InitialKeyRepeat 2>/dev/null || true
    defaults delete NSGlobalDomain AppleKeyboardUIMode 2>/dev/null || true

    defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode 2>/dev/null || true
    defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 2>/dev/null || true
    defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint 2>/dev/null || true
    defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint2 2>/dev/null || true

    defaults delete com.apple.screensaver askForPassword 2>/dev/null || true
    defaults delete com.apple.screensaver askForPasswordDelay 2>/dev/null || true

    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true

    log_success "macOS defaults reset"
    log_info "Some settings require logout/restart"
}

uninstall_claude() {
    log_step "Uninstalling Claude Code configuration"

    local claude_dir="$HOME/.claude"

    [[ -L "$claude_dir/CLAUDE.md" ]] && run_cmd rm -f "$claude_dir/CLAUDE.md"
    [[ -L "$claude_dir/settings.json" ]] && run_cmd rm -f "$claude_dir/settings.json"
    [[ -L "$claude_dir/settings.local.json" ]] && run_cmd rm -f "$claude_dir/settings.local.json"

    log_success "Claude Code configuration removed"
    log_info "~/.claude directory preserved"
}

cmd_uninstall() {
    local components=("$@")

    if [[ ${#components[@]} -eq 0 ]]; then
        local installed=()
        while IFS= read -r comp; do
            installed+=("$comp")
        done < <(list_installed_components)

        if [[ ${#installed[@]} -eq 0 ]]; then
            log_info "No components installed"
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

        # Uninstall in reverse order
        local reverse_order
        reverse_order=$(echo "$DEFAULT_INSTALL_ORDER" | tr ' ' '\n' | tac | tr '\n' ' ')
        for comp in $reverse_order; do
            if [[ " ${installed[*]} " == *" $comp "* ]]; then
                components+=("$comp")
            fi
        done
        is_component_installed "macos" && components=("macos" "${components[@]}")
    fi

    if ! validate_components "${components[@]}"; then
        return 1
    fi

    log_step "Uninstalling: ${components[*]}"

    [[ "$DRY_RUN" == "true" ]] && log_warning "DRY-RUN MODE"

    echo

    for component in "${components[@]}"; do
        case "$component" in
            zsh)    uninstall_zsh ;;
            git)    uninstall_git ;;
            node)   uninstall_node ;;
            ruby)   uninstall_ruby ;;
            fonts)  uninstall_fonts ;;
            claude) uninstall_claude ;;
            cli)    uninstall_cli ;;
            apps)   uninstall_apps ;;
            macos)  uninstall_macos ;;
            *)      log_warning "No uninstall for: $component" ;;
        esac
        remove_install_marker "$component"
        echo
    done

    log_step "Uninstall complete"
    log_info "Restart your shell for changes to take effect"
}
