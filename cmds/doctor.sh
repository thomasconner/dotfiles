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
                log_success "$name: OK"
                return 0
            fi
        fi

        # Symlink exists but points to wrong location or broken
        log_warning "$name: symlink points to wrong location"
        echo "      Expected: $expected_source"
        echo "      Actual: $(readlink "$target")"
        return 1
    elif [[ -f "$target" ]]; then
        log_warning "$name: file exists but is not a symlink"
        echo "      Fix: backup and re-run ctdev install"
        return 1
    else
        log_info "$name: not configured"
        return 1
    fi
}

check_command() {
    local name="$1"
    local cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        log_success "$name: installed"
        return 0
    else
        log_warning "$name: not installed"
        return 1
    fi
}

check_directory() {
    local name="$1"
    local dir="$2"

    if [[ -d "$dir" ]]; then
        log_success "$name: OK"
        return 0
    else
        log_warning "$name: directory missing"
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
        log_success "user: $git_name <$git_email>"
    else
        if [[ -z "$git_name" ]]; then
            log_warning "user.name: not configured"
            ((issues++))
        fi
        if [[ -z "$git_email" ]]; then
            log_warning "user.email: not configured"
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
            log_success "claude-code: installed"
        else
            log_info "claude-code: not installed (optional)"
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
        log_success "rbenv: OK"
    elif command -v ruby >/dev/null 2>&1; then
        log_info "rbenv: not installed (using system Ruby)"
    else
        log_warning "rbenv: not installed"
        ((issues++))
    fi

    check_command "ruby" "ruby" || ((issues++))
    check_command "gem" "gem" || ((issues++))

    # Check gems
    if command -v gem >/dev/null 2>&1; then
        if gem list colorls | grep -q colorls; then
            log_success "colorls: installed"
        else
            log_info "colorls: not installed (optional)"
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
        log_warning "Oh My Zsh custom directory not found"
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
    check_shell_config_health || ((total_issues+=$?))

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
