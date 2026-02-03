#!/usr/bin/env bash

# ctdev upgrade - Upgrade installed components

OS=$(detect_os)
PKG_MGR=$(get_package_manager)

# ============================================================================
# Helper: git pull default branch
# ============================================================================

git_pull_default_branch() {
    local repo_path="$1"
    local name="$2"

    if [[ ! -d "$repo_path/.git" ]]; then
        log_warning "$name: Not a git repository"
        return 1
    fi

    local default_branch
    default_branch=$(git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [[ -z "$default_branch" ]]; then
        default_branch="main"
    fi

    git -C "$repo_path" pull origin "$default_branch" --ff-only 2>/dev/null || \
        log_warning "$name: Could not pull (may have local changes)"
}

# ============================================================================
# System Upgrade Functions
# ============================================================================

upgrade_system_packages() {
    log_step "Upgrading System Packages"

    case "$PKG_MGR" in
        apt)
            log_info "Upgrading apt packages..."
            run_cmd maybe_sudo apt full-upgrade -y --fix-missing

            log_info "Removing unnecessary packages..."
            run_cmd maybe_sudo apt autoremove -y

            log_info "Cleaning package cache..."
            run_cmd maybe_sudo apt autoclean
            ;;
        dnf)
            log_info "Upgrading dnf packages..."
            run_cmd maybe_sudo dnf upgrade -y

            log_info "Removing unnecessary packages..."
            run_cmd maybe_sudo dnf autoremove -y
            ;;
        pacman)
            log_info "Upgrading pacman packages..."
            run_cmd maybe_sudo pacman -Syu --noconfirm

            log_info "Removing orphaned packages..."
            run_cmd maybe_sudo pacman -Rns "$(pacman -Qtdq)" --noconfirm 2>/dev/null || true
            ;;
        brew)
            log_info "Upgrading Homebrew packages..."
            run_cmd brew upgrade

            log_info "Upgrading casks..."
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] Would run: brew upgrade --cask"
            else
                brew upgrade --cask 2>&1 | while read -r line; do
                    if [[ "$line" == *"has been disabled"* ]] || [[ "$line" == *"Error"* ]]; then
                        log_warning "$line"
                    else
                        echo "$line"
                    fi
                done || true
            fi

            log_info "Cleaning up old versions..."
            run_cmd brew cleanup
            ;;
        pkg)
            log_info "Upgrading FreeBSD packages..."
            run_cmd maybe_sudo pkg upgrade -y
            run_cmd maybe_sudo pkg autoremove -y
            ;;
        *)
            log_warning "Unknown package manager: $PKG_MGR"
            ;;
    esac

    log_success "System packages upgraded"
}

# ============================================================================
# Component Upgrade Functions
# ============================================================================

upgrade_zsh() {
    if ! is_component_installed "zsh"; then
        return
    fi

    log_info "Upgrading zsh components..."

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update Oh My Zsh"
        else
            git_pull_default_branch "$HOME/.oh-my-zsh" "Oh My Zsh"
        fi
    fi

    # Plugins
    local plugins=(
        "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
        "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
    )

    for plugin_dir in "${plugins[@]}"; do
        if [[ -d "$plugin_dir/.git" ]]; then
            local plugin_name
            plugin_name=$(basename "$plugin_dir")
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] Would update $plugin_name"
            else
                git_pull_default_branch "$plugin_dir" "$plugin_name"
            fi
        fi
    done

    # Pure prompt
    if [[ -d "$HOME/.zsh/pure/.git" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update Pure prompt"
        else
            git_pull_default_branch "$HOME/.zsh/pure" "Pure prompt"
        fi
    fi
}

upgrade_node() {
    if ! is_component_installed "node"; then
        return
    fi

    log_info "Upgrading node components..."

    # Update nodenv if installed via git
    if [[ -d "$HOME/.nodenv/.git" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update nodenv"
        else
            git_pull_default_branch "$HOME/.nodenv" "nodenv"
            if [[ -d "$HOME/.nodenv/plugins/node-build/.git" ]]; then
                git_pull_default_branch "$HOME/.nodenv/plugins/node-build" "node-build"
            fi
        fi
    fi

    # Update npm packages
    if command -v npm >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would run: npm update -g"
        else
            npm update -g 2>/dev/null || log_warning "Could not update npm global packages"
        fi
    fi
}

upgrade_ruby() {
    if ! is_component_installed "ruby"; then
        return
    fi

    log_info "Upgrading ruby components..."

    # Update rbenv if installed via git
    if [[ -d "$HOME/.rbenv/.git" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update rbenv"
        else
            git_pull_default_branch "$HOME/.rbenv" "rbenv"
            if [[ -d "$HOME/.rbenv/plugins/ruby-build/.git" ]]; then
                git_pull_default_branch "$HOME/.rbenv/plugins/ruby-build" "ruby-build"
            fi
        fi
    fi

    # Update gems
    if command -v gem >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update gems"
        else
            gem update --system 2>/dev/null || log_warning "Could not update RubyGems"
            gem update 2>/dev/null || log_warning "Could not update gems"
        fi
    fi
}

upgrade_bun() {
    if ! is_component_installed "bun"; then
        return
    fi

    log_info "Upgrading bun..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: bun upgrade"
    else
        if command -v bun >/dev/null 2>&1; then
            bun upgrade 2>/dev/null || log_warning "Could not upgrade bun"
        elif [[ -x "$HOME/.bun/bin/bun" ]]; then
            "$HOME/.bun/bin/bun" upgrade 2>/dev/null || log_warning "Could not upgrade bun"
        fi
    fi
}

upgrade_gh() {
    if ! is_component_installed "gh"; then
        return
    fi

    log_info "Upgrading gh extensions..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: gh extension upgrade --all"
    else
        gh extension upgrade --all 2>/dev/null || log_info "No gh extensions to update"
    fi
}

upgrade_claude_code() {
    if ! is_component_installed "claude-code"; then
        return
    fi

    log_info "Upgrading claude-code..."

    # Claude Code auto-updates via native installer, but we can trigger it
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: claude update"
    else
        if command -v claude >/dev/null 2>&1; then
            claude update 2>/dev/null || log_info "Claude Code is up to date or auto-updates"
        fi
    fi
}

# ============================================================================
# Main command
# ============================================================================

cmd_upgrade() {
    local skip_prompt=false
    local components=()

    # Parse subcommand arguments
    for arg in "$@"; do
        case "$arg" in
            -h|--help|-v|--verbose|-n|--dry-run)
                # Already handled by main dispatcher
                ;;
            -y|--yes)
                skip_prompt=true
                ;;
            *)
                components+=("$arg")
                ;;
        esac
    done

    log_step "Checking for upgrades"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    log_info "OS: $OS"
    log_info "Package manager: $PKG_MGR"
    echo

    # Determine what will be upgraded
    local to_upgrade=()

    if [[ ${#components[@]} -gt 0 ]]; then
        # Validate specified components
        if ! validate_components "${components[@]}"; then
            return 1
        fi
        for comp in "${components[@]}"; do
            if is_component_installed "$comp"; then
                to_upgrade+=("$comp")
            else
                log_warning "$comp is not installed"
            fi
        done
    else
        # Upgrade all installed components
        to_upgrade=("system")
        while IFS= read -r comp; do
            to_upgrade+=("$comp")
        done < <(list_installed_components)
    fi

    if [[ ${#to_upgrade[@]} -eq 0 ]]; then
        log_info "Nothing to upgrade"
        return 0
    fi

    # Show what will be upgraded
    echo "The following will be upgraded:"
    for item in "${to_upgrade[@]}"; do
        echo "  $item"
    done
    echo

    # Prompt for confirmation unless -y flag
    if [[ "$skip_prompt" != "true" ]] && [[ "$DRY_RUN" != "true" ]]; then
        if [[ -t 0 ]]; then
            printf "Proceed? [y/N] "
            if ! read -r -t 30 answer || [[ ! "$answer" =~ ^[Yy]$ ]]; then
                log_info "Aborted"
                return 0
            fi
            echo
        fi
    fi

    # Run upgrades
    local upgraded=()

    # System packages first (if no specific components requested)
    if [[ ${#components[@]} -eq 0 ]]; then
        upgrade_system_packages
        upgraded+=("system")
        echo
    fi

    # Component-specific upgrades
    upgrade_zsh && upgraded+=("zsh")
    upgrade_node && upgraded+=("node")
    upgrade_ruby && upgraded+=("ruby")
    upgrade_bun && upgraded+=("bun")
    upgrade_gh && upgraded+=("gh")
    upgrade_claude_code && upgraded+=("claude-code")

    echo
    log_step "Upgrade Complete"

    if [[ ${#upgraded[@]} -gt 0 ]]; then
        log_success "Upgraded: ${upgraded[*]}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry-run. Run without --dry-run to apply changes."
    else
        log_info "You may need to restart your shell for some changes to take effect"
    fi

    return 0
}
