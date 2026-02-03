#!/usr/bin/env bash

# ctdev uninstall - Remove installed components

OS=$(detect_os)
PKG_MGR=$(get_package_manager)

# ============================================================================
# Uninstall Functions - Desktop Applications
# ============================================================================

uninstall_1password() {
    log_info "Uninstalling 1Password..."
    if [[ "$OS" == "macos" ]]; then
        if [[ -d "/Applications/1Password.app" ]]; then
            run_cmd brew uninstall --cask 1password || log_warning "Could not uninstall via brew"
        fi
    else
        log_info "Remove 1password via your package manager"
    fi
}

uninstall_chrome() {
    log_info "Uninstalling Chrome..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask google-chrome || log_warning "Could not uninstall via brew"
    else
        log_info "Remove google-chrome via your package manager"
    fi
}

uninstall_cleanmymac() {
    log_info "Uninstalling CleanMyMac..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask cleanmymac || log_warning "Could not uninstall via brew"
    fi
}

uninstall_claude_desktop() {
    log_info "Uninstalling Claude Desktop..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask claude || log_warning "Could not uninstall via brew"
    fi
}

uninstall_dbeaver() {
    log_info "Uninstalling DBeaver..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask dbeaver-community || log_warning "Could not uninstall via brew"
    else
        log_info "Remove dbeaver via your package manager"
    fi
}

uninstall_ghostty() {
    log_info "Uninstalling Ghostty..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask ghostty || log_warning "Could not uninstall via brew"
    else
        log_info "Remove ghostty via your package manager or build system"
    fi
}

uninstall_linear() {
    log_info "Uninstalling Linear..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask linear-linear || log_warning "Could not uninstall via brew"
    fi
}

uninstall_logi_options() {
    log_info "Uninstalling Logi Options+..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask logi-options-plus || log_warning "Could not uninstall via brew"
    fi
}

uninstall_slack() {
    log_info "Uninstalling Slack..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask slack || log_warning "Could not uninstall via brew"
    else
        log_info "Remove slack via your package manager"
    fi
}

uninstall_tradingview() {
    log_info "Uninstalling TradingView..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask tradingview || log_warning "Could not uninstall via brew"
    fi
}

uninstall_vscode() {
    log_info "Uninstalling VS Code..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask visual-studio-code || log_warning "Could not uninstall via brew"
    else
        log_info "Remove code via your package manager"
    fi
}

# ============================================================================
# Uninstall Functions - CLI Tools
# ============================================================================

uninstall_age() {
    log_info "Uninstalling age..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall age || true
    else
        [[ -f "/usr/local/bin/age" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/age
        [[ -f "/usr/local/bin/age-keygen" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/age-keygen
    fi
}

uninstall_btop() {
    log_info "Uninstalling btop..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall btop || true
    else
        log_info "Remove btop via your package manager"
    fi
}

uninstall_bun() {
    log_info "Uninstalling bun..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall bun || true
    else
        [[ -d "$HOME/.bun" ]] && run_cmd rm -rf "$HOME/.bun"
    fi
}

uninstall_claude_code() {
    log_info "Uninstalling Claude Code..."

    # Remove CLI
    if [[ -x "$HOME/.local/bin/claude" ]]; then
        run_cmd rm -f "$HOME/.local/bin/claude"
    fi

    # Remove config symlinks
    [[ -L "$HOME/.claude/CLAUDE.md" ]] && run_cmd rm -f "$HOME/.claude/CLAUDE.md"
    [[ -L "$HOME/.claude/settings.json" ]] && run_cmd rm -f "$HOME/.claude/settings.json"
    [[ -L "$HOME/.claude/settings.local.json" ]] && run_cmd rm -f "$HOME/.claude/settings.local.json"

    log_info "~/.claude directory preserved"
}

uninstall_docker() {
    log_info "Uninstalling Docker..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall --cask docker || true
    else
        log_info "Remove docker via your package manager"
    fi
}

uninstall_doctl() {
    log_info "Uninstalling doctl..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall doctl || true
    else
        [[ -f "/usr/local/bin/doctl" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/doctl
    fi
}

uninstall_gh() {
    log_info "Uninstalling gh..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall gh || true
    else
        log_info "Remove gh via your package manager"
    fi
}

uninstall_git_spice() {
    log_info "Uninstalling git-spice..."
    if command -v gs >/dev/null 2>&1; then
        # Installed via go
        [[ -f "$HOME/go/bin/gs" ]] && run_cmd rm -f "$HOME/go/bin/gs"
    fi
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall git-spice || true
    fi
}

uninstall_helm() {
    log_info "Uninstalling helm..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall helm || true
    else
        [[ -f "/usr/local/bin/helm" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/helm
    fi
}

uninstall_jq() {
    log_info "Uninstalling jq..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall jq || true
    else
        log_info "Remove jq via your package manager"
    fi
}

uninstall_kubectl() {
    log_info "Uninstalling kubectl..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall kubectl || true
    else
        [[ -f "/usr/local/bin/kubectl" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/kubectl
    fi
}

uninstall_shellcheck() {
    log_info "Uninstalling shellcheck..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall shellcheck || true
    else
        log_info "Remove shellcheck via your package manager"
    fi
}

uninstall_sops() {
    log_info "Uninstalling sops..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall sops || true
    else
        [[ -f "/usr/local/bin/sops" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/sops
    fi
}

uninstall_terraform() {
    log_info "Uninstalling terraform..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall terraform || true
    else
        [[ -f "/usr/local/bin/terraform" ]] && run_cmd maybe_sudo rm -f /usr/local/bin/terraform
    fi
}

uninstall_tmux() {
    log_info "Uninstalling tmux..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd brew uninstall tmux || true
    else
        log_info "Remove tmux via your package manager"
    fi
    # Remove config
    [[ -L "$HOME/.tmux.conf" ]] && run_cmd rm -f "$HOME/.tmux.conf"
}

# ============================================================================
# Uninstall Functions - Configuration & Languages
# ============================================================================

uninstall_fonts() {
    log_info "Uninstalling Nerd Fonts..."
    if [[ "$OS" == "macos" ]]; then
        run_cmd rm -f ~/Library/Fonts/*Nerd*
    else
        run_cmd rm -rf ~/.local/share/fonts/*Nerd*
    fi
}

uninstall_git() {
    log_info "Uninstalling git configuration..."
    [[ -L "$HOME/.gitconfig" ]] && run_cmd rm -f "$HOME/.gitconfig"
    [[ -L "$HOME/.gitignore" ]] && run_cmd rm -f "$HOME/.gitignore"
    log_info ".gitconfig.local preserved"
}

uninstall_node() {
    log_info "Uninstalling Node.js (nodenv)..."
    if [[ -d "$HOME/.nodenv" ]]; then
        run_cmd rm -rf "$HOME/.nodenv"
    fi
}

uninstall_ruby() {
    log_info "Uninstalling Ruby (rbenv)..."
    if [[ -d "$HOME/.rbenv" ]]; then
        run_cmd rm -rf "$HOME/.rbenv"
    fi
}

uninstall_zsh() {
    log_info "Uninstalling zsh configuration..."

    local custom_dir="$HOME/.oh-my-zsh/custom"
    if [[ -d "$custom_dir" ]]; then
        run_cmd rm -f "$custom_dir/aliases.zsh"
        run_cmd rm -f "$custom_dir/exports.zsh"
        run_cmd rm -f "$custom_dir/path.zsh"
        run_cmd rm -f "$custom_dir/exports.local.zsh"
    fi

    [[ -d "$HOME/.zsh/pure" ]] && run_cmd rm -rf "$HOME/.zsh/pure"
    [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] && run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]] && run_cmd rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
    [[ -L "$HOME/.zshrc" ]] && run_cmd rm -f "$HOME/.zshrc"

    log_info "Oh My Zsh kept. Run 'uninstall_oh_my_zsh' to remove it."
}

# ============================================================================
# Dispatch uninstall by component name
# ============================================================================

run_uninstall() {
    local component="$1"

    case "$component" in
        1password)       uninstall_1password ;;
        age)             uninstall_age ;;
        btop)            uninstall_btop ;;
        bun)             uninstall_bun ;;
        chrome)          uninstall_chrome ;;
        cleanmymac)      uninstall_cleanmymac ;;
        claude-code)     uninstall_claude_code ;;
        claude-desktop)  uninstall_claude_desktop ;;
        dbeaver)         uninstall_dbeaver ;;
        docker)          uninstall_docker ;;
        doctl)           uninstall_doctl ;;
        fonts)           uninstall_fonts ;;
        gh)              uninstall_gh ;;
        ghostty)         uninstall_ghostty ;;
        git)             uninstall_git ;;
        git-spice)       uninstall_git_spice ;;
        helm)            uninstall_helm ;;
        jq)              uninstall_jq ;;
        kubectl)         uninstall_kubectl ;;
        linear)          uninstall_linear ;;
        logi-options)    uninstall_logi_options ;;
        node)            uninstall_node ;;
        ruby)            uninstall_ruby ;;
        shellcheck)      uninstall_shellcheck ;;
        slack)           uninstall_slack ;;
        sops)            uninstall_sops ;;
        terraform)       uninstall_terraform ;;
        tmux)            uninstall_tmux ;;
        tradingview)     uninstall_tradingview ;;
        vscode)          uninstall_vscode ;;
        zsh)             uninstall_zsh ;;
        *)
            log_warning "No uninstall handler for: $component"
            return 1
            ;;
    esac
}

# ============================================================================
# Main command
# ============================================================================

cmd_uninstall() {
    local components=()

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            -h|--help|-v|--verbose|-n|--dry-run|-f|--force)
                # Already handled by main dispatcher
                ;;
            *)
                components+=("$arg")
                ;;
        esac
    done

    # Require at least one component
    if [[ ${#components[@]} -eq 0 ]]; then
        log_error "No components specified"
        echo ""
        echo "Usage: ctdev uninstall <component...>"
        echo ""
        echo "Installed components:"
        list_installed_components | while read -r name; do
            echo "  $name"
        done
        return 1
    fi

    # Validate specified components
    if ! validate_components "${components[@]}"; then
        return 1
    fi

    log_step "Uninstalling: ${components[*]}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    echo

    local uninstalled=()
    local failed=()

    for component in "${components[@]}"; do
        if ! is_component_installed "$component"; then
            log_info "$component is not installed"
            continue
        fi

        if run_uninstall "$component"; then
            remove_install_marker "$component"
            uninstalled+=("$component")
        else
            failed+=("$component")
        fi
        echo
    done

    # Summary
    log_step "Uninstall Complete"

    if [[ ${#uninstalled[@]} -gt 0 ]]; then
        log_success "Uninstalled: ${uninstalled[*]}"
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed: ${failed[*]}"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry-run. Run without --dry-run to apply changes."
    else
        log_info "Restart your shell for changes to take effect"
    fi

    return 0
}
