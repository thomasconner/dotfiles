#!/usr/bin/env bash

# ctdev doctor - Diagnose installation health

# ============================================================================
# Health check functions
# ============================================================================

check_symlink() {
    local name="$1"
    local target="$2"
    local expected_source="$3"

    if [[ -L "$target" ]]; then
        # Check if symlink target actually exists and resolves to expected file
        if [[ -e "$target" ]]; then
            # Both exist - compare real paths
            local actual_real expected_real
            actual_real=$(realpath "$target" 2>/dev/null) || actual_real=""
            expected_real=$(realpath "$expected_source" 2>/dev/null) || expected_real=""

            if [[ -n "$actual_real" && "$actual_real" == "$expected_real" ]]; then
                log_check_pass "$name" "OK"
                return 0
            fi
        fi

        # Symlink exists but points to wrong location or broken
        log_check_fail "$name" "symlink points to wrong location"
        echo "      Expected: $expected_source"
        echo "      Actual: $(readlink "$target")"
        return 1
    elif [[ -f "$target" ]]; then
        log_check_fail "$name" "file exists but is not a symlink"
        echo "      Fix: backup and re-run ctdev install"
        return 1
    else
        log_check_fail "$name" "not configured"
        return 1
    fi
}

check_command() {
    local name="$1"
    local cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        log_check_pass "$name" "installed"
        return 0
    else
        log_check_fail "$name" "not installed"
        return 1
    fi
}

check_directory() {
    local name="$1"
    local dir="$2"

    if [[ -d "$dir" ]]; then
        log_check_pass "$name" "OK"
        return 0
    else
        log_check_fail "$name" "directory missing"
        echo "      Expected: $dir"
        return 1
    fi
}

# ============================================================================
# Component checks
# ============================================================================

check_zsh_health() {
    log_step "Checking Zsh"
    local issues=0

    check_command "zsh" "zsh" || ((issues++))
    check_directory "Oh My Zsh" "$HOME/.oh-my-zsh" || ((issues++))
    check_directory "Pure prompt" "$HOME/.zsh/pure" || ((issues++))
    check_directory "zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" || ((issues++))
    check_directory "zsh-completions" "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" || ((issues++))
    check_symlink ".zshrc" "$HOME/.zshrc" "${DOTFILES_ROOT}/components/zsh/.zshrc" || ((issues++))

    echo
    return $issues
}

check_git_health() {
    log_step "Checking Git"
    local issues=0

    check_command "git" "git" || ((issues++))
    check_symlink ".gitconfig" "$HOME/.gitconfig" "${DOTFILES_ROOT}/components/git/.gitconfig" || ((issues++))
    check_symlink ".gitignore" "$HOME/.gitignore" "${DOTFILES_ROOT}/components/git/.gitignore" || ((issues++))

    # Check user configuration
    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$git_name" && -n "$git_email" ]]; then
        log_check_pass "user" "$git_name <$git_email>"
    else
        if [[ -z "$git_name" ]]; then
            log_check_fail "user.name" "not configured"
            ((issues++))
        fi
        if [[ -z "$git_email" ]]; then
            log_check_fail "user.email" "not configured"
            ((issues++))
        fi
        log_info "Run: ctdev install git --name 'Your Name' --email 'your@email.com'"
    fi

    echo
    return $issues
}

check_node_health() {
    log_step "Checking Node.js"
    local issues=0

    check_directory "nodenv" "$HOME/.nodenv" || ((issues++))
    check_command "node" "node" || ((issues++))
    check_command "npm" "npm" || ((issues++))

    # Check global packages
    if command -v npm >/dev/null 2>&1; then
        if npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
            log_check_pass "claude-code" "installed"
        else
            log_check_fail "claude-code" "not installed (optional)"
        fi
    fi

    echo
    return $issues
}

check_ruby_health() {
    log_step "Checking Ruby"
    local issues=0

    # Check if rbenv is installed, or if system Ruby is being used
    if [[ -d "$HOME/.rbenv" ]]; then
        log_check_pass "rbenv" "OK"
    elif command -v ruby >/dev/null 2>&1; then
        log_check_fail "rbenv" "not installed (using system Ruby)"
    else
        log_check_fail "rbenv" "not installed"
        ((issues++))
    fi

    check_command "ruby" "ruby" || ((issues++))
    check_command "gem" "gem" || ((issues++))

    # Check gems
    if command -v gem >/dev/null 2>&1; then
        if gem list colorls | grep -q colorls; then
            log_check_pass "colorls" "installed"
        else
            log_check_fail "colorls" "not installed (optional)"
        fi
    fi

    echo
    return $issues
}

check_cli_health() {
    log_step "Checking CLI Tools"
    local issues=0

    check_command "jq" "jq" || ((issues++))
    check_command "gh" "gh" || ((issues++))
    check_command "kubectl" "kubectl" || ((issues++))
    check_command "doctl" "doctl" || ((issues++))
    check_command "helm" "helm" || ((issues++))
    check_command "btop" "btop" || ((issues++))
    check_command "age" "age" || ((issues++))
    check_command "sops" "sops" || ((issues++))
    check_command "terraform" "terraform" || ((issues++))
    check_command "docker" "docker" || ((issues++))

    echo
    return $issues
}

check_shell_config_health() {
    log_step "Checking Shell Configuration"
    local issues=0
    local custom_dir="$HOME/.oh-my-zsh/custom"

    if [[ -d "$custom_dir" ]]; then
        check_symlink "aliases.zsh" "$custom_dir/aliases.zsh" "${DOTFILES_ROOT}/shell/aliases.zsh" || ((issues++))
        check_symlink "exports.zsh" "$custom_dir/exports.zsh" "${DOTFILES_ROOT}/shell/exports.zsh" || ((issues++))
        check_symlink "path.zsh" "$custom_dir/path.zsh" "${DOTFILES_ROOT}/shell/path.zsh" || ((issues++))
    else
        log_check_fail "Oh My Zsh custom directory" "not found"
        ((issues++))
    fi

    echo
    return $issues
}

check_apps_health() {
    log_step "Checking Applications"
    local issues=0

    # Check for commonly installed apps
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS - check Applications folder
        if [[ -d "/Applications/Visual Studio Code.app" ]] || command -v code >/dev/null 2>&1; then
            log_check_pass "VS Code" "installed"
        else
            log_check_fail "VS Code" "not installed (optional)"
        fi

        if [[ -d "/Applications/Cursor.app" ]] || command -v cursor >/dev/null 2>&1; then
            log_check_pass "Cursor" "installed"
        else
            log_check_fail "Cursor" "not installed (optional)"
        fi

        if [[ -d "/Applications/Google Chrome.app" ]]; then
            log_check_pass "Chrome" "installed"
        else
            log_check_fail "Chrome" "not installed (optional)"
        fi

        if [[ -d "/Applications/Slack.app" ]]; then
            log_check_pass "Slack" "installed"
        else
            log_check_fail "Slack" "not installed (optional)"
        fi

        if [[ -d "/Applications/Claude.app" ]]; then
            log_check_pass "Claude" "installed"
        else
            log_check_fail "Claude" "not installed (optional)"
        fi

        if [[ -d "/Applications/1Password.app" ]]; then
            log_check_pass "1Password" "installed"
        else
            log_check_fail "1Password" "not installed (optional)"
        fi

        if [[ -d "/Applications/DBeaver.app" ]]; then
            log_check_pass "DBeaver" "installed"
        else
            log_check_fail "DBeaver" "not installed (optional)"
        fi

        if [[ -d "/Applications/TradingView.app" ]]; then
            log_check_pass "TradingView" "installed"
        else
            log_check_fail "TradingView" "not installed (optional)"
        fi

        if [[ -d "/Applications/Linear.app" ]]; then
            log_check_pass "Linear" "installed"
        else
            log_check_fail "Linear" "not installed (optional)"
        fi

        if [[ -d "/Applications/CleanMyMac.app" ]] || [[ -d "/Applications/CleanMyMac_5.app" ]]; then
            log_check_pass "CleanMyMac" "installed"
        else
            log_check_fail "CleanMyMac" "not installed (optional)"
        fi

        if [[ -d "/Applications/logioptionsplus.app" ]]; then
            log_check_pass "Logi Options+" "installed"
        else
            log_check_fail "Logi Options+" "not installed (optional)"
        fi
    else
        # Linux - check commands and common paths
        if command -v code >/dev/null 2>&1; then
            log_check_pass "VS Code" "installed"
        else
            log_check_fail "VS Code" "not installed (optional)"
        fi

        if command -v cursor >/dev/null 2>&1 || [[ -f "$HOME/Applications/cursor/cursor.AppImage" ]]; then
            log_check_pass "Cursor" "installed"
        else
            log_check_fail "Cursor" "not installed (optional)"
        fi

        if command -v google-chrome >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
            log_check_pass "Chrome/Chromium" "installed"
        else
            log_check_fail "Chrome/Chromium" "not installed (optional)"
        fi

        if command -v slack >/dev/null 2>&1 || flatpak list 2>/dev/null | grep -q Slack; then
            log_check_pass "Slack" "installed"
        else
            log_check_fail "Slack" "not installed (optional)"
        fi

        if command -v 1password >/dev/null 2>&1; then
            log_check_pass "1Password" "installed"
        else
            log_check_fail "1Password" "not installed (optional)"
        fi

        if command -v dbeaver >/dev/null 2>&1 || command -v dbeaver-ce >/dev/null 2>&1; then
            log_check_pass "DBeaver" "installed"
        else
            log_check_fail "DBeaver" "not installed (optional)"
        fi

        if command -v tradingview >/dev/null 2>&1 || dpkg -l tradingview &>/dev/null; then
            log_check_pass "TradingView" "installed"
        else
            log_check_fail "TradingView" "not installed (optional)"
        fi
    fi

    # tmux (cross-platform)
    if command -v tmux >/dev/null 2>&1; then
        log_check_pass "tmux" "installed"
    else
        log_check_fail "tmux" "not installed (optional)"
    fi

    echo
    return $issues
}

check_fonts_health() {
    log_step "Checking Fonts"
    local issues=0

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS - check ~/Library/Fonts
        if ls ~/Library/Fonts/*Nerd* >/dev/null 2>&1; then
            local font_count
            font_count=$(ls ~/Library/Fonts/*Nerd* 2>/dev/null | wc -l | tr -d ' ')
            log_check_pass "Nerd Fonts" "${font_count} fonts installed"
        else
            log_check_fail "Nerd Fonts" "not installed"
            ((issues++))
        fi
    else
        # Linux - check ~/.local/share/fonts or /usr/share/fonts
        if ls ~/.local/share/fonts/*Nerd* >/dev/null 2>&1; then
            local font_count
            font_count=$(ls ~/.local/share/fonts/*Nerd* 2>/dev/null | wc -l | tr -d ' ')
            log_check_pass "Nerd Fonts" "${font_count} fonts installed"
        elif ls /usr/share/fonts/*Nerd* >/dev/null 2>&1; then
            local font_count
            font_count=$(ls /usr/share/fonts/*Nerd* 2>/dev/null | wc -l | tr -d ' ')
            log_check_pass "Nerd Fonts" "${font_count} fonts installed (system)"
        else
            log_check_fail "Nerd Fonts" "not installed"
            ((issues++))
        fi
    fi

    echo
    return $issues
}

check_macos_health() {
    # Only run on macOS
    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 0
    fi

    log_step "Checking macOS Defaults"
    local issues=0

    # Check key defaults that indicate the component was installed
    if [[ "$(defaults read com.apple.dock show-recents 2>/dev/null)" == "0" ]]; then
        log_check_pass "Dock settings" "configured"
    else
        log_check_fail "Dock settings" "not configured"
        ((issues++))
    fi

    if [[ "$(defaults read com.apple.finder ShowPathbar 2>/dev/null)" == "1" ]]; then
        log_check_pass "Finder settings" "configured"
    else
        log_check_fail "Finder settings" "not configured"
        ((issues++))
    fi

    if [[ "$(defaults read NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 2>/dev/null)" == "0" ]]; then
        log_check_pass "Keyboard settings" "configured"
    else
        log_check_fail "Keyboard settings" "not configured"
        ((issues++))
    fi

    echo
    return $issues
}

# ============================================================================
# Main command
# ============================================================================

cmd_doctor() {
    local total_issues=0

    log_step "ctdev doctor"
    log_info "Checking installation health..."
    echo

    check_zsh_health || ((total_issues+=$?))
    check_git_health || ((total_issues+=$?))
    check_node_health || ((total_issues+=$?))
    check_ruby_health || ((total_issues+=$?))
    check_cli_health || ((total_issues+=$?))
    check_apps_health || ((total_issues+=$?))
    check_fonts_health || ((total_issues+=$?))
    check_shell_config_health || ((total_issues+=$?))
    check_macos_health || ((total_issues+=$?))

    log_step "Summary"

    if [[ $total_issues -eq 0 ]]; then
        log_success "All checks passed! Your installation is healthy."
    else
        log_warning "Found $total_issues potential issue(s)"
        echo
        echo "To fix issues, try:"
        echo "  ctdev install <component>    # Reinstall a specific component"
        echo "  ctdev update                 # Update all components"
    fi

    echo
    return 0
}
