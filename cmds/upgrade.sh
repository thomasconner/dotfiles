#!/usr/bin/env bash

# ctdev upgrade - Upgrade installed components

OS=$(detect_os)
PKG_MGR=$(get_package_manager)

# ============================================================================
# Version detection helpers
# ============================================================================

get_apt_upgradable() {
    apt list --upgradable 2>/dev/null | grep -v "^Listing" | while read -r line; do
        local pkg ver_new ver_old
        pkg=$(echo "$line" | cut -d'/' -f1)
        ver_new=$(echo "$line" | awk '{print $2}')
        ver_old=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')
        if [[ -n "$ver_old" ]]; then
            echo "$pkg: $ver_old → $ver_new"
        else
            echo "$pkg: → $ver_new"
        fi
    done
}

get_brew_upgradable() {
    brew outdated --verbose 2>/dev/null | while read -r line; do
        echo "$line" | sed 's/ (.*) < / → /' | sed 's/ \[pinned at .*\]//'
    done
}

git_repo_has_updates() {
    local repo_path="$1"
    [[ -d "$repo_path/.git" ]] || return 1
    git -C "$repo_path" fetch --quiet 2>/dev/null || return 1
    local behind
    behind=$(git -C "$repo_path" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || return 1
    [[ "$behind" -gt 0 ]]
}

git_pull_default_branch() {
    local repo_path="$1"
    local name="$2"
    [[ -d "$repo_path/.git" ]] || return 1
    local default_branch
    default_branch=$(git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    [[ -z "$default_branch" ]] && default_branch="main"
    git -C "$repo_path" pull origin "$default_branch" --ff-only 2>/dev/null || \
        log_warning "$name: Could not pull (may have local changes)"
}

# ============================================================================
# System Upgrade
# ============================================================================

upgrade_system_packages() {
    case "$PKG_MGR" in
        apt)
            run_cmd maybe_sudo apt full-upgrade -y --fix-missing
            run_cmd maybe_sudo apt autoremove -y --quiet
            run_cmd maybe_sudo apt autoclean --quiet
            ;;
        dnf)
            run_cmd maybe_sudo dnf upgrade -y
            run_cmd maybe_sudo dnf autoremove -y
            ;;
        pacman)
            run_cmd maybe_sudo pacman -Syu --noconfirm
            run_cmd maybe_sudo pacman -Rns "$(pacman -Qtdq)" --noconfirm 2>/dev/null || true
            ;;
        brew)
            run_cmd brew upgrade
            brew upgrade --cask 2>/dev/null || true
            run_cmd brew cleanup --quiet
            ;;
    esac
}

# ============================================================================
# Component-specific upgrades (only for components with special upgrade needs)
# ============================================================================

check_zsh_updates() {
    is_component_installed "zsh" || return 1
    git_repo_has_updates "$HOME/.oh-my-zsh" && return 0
    git_repo_has_updates "$HOME/.zsh/pure" && return 0
    return 1
}

upgrade_zsh() {
    is_component_installed "zsh" || return
    [[ -d "$HOME/.oh-my-zsh/.git" ]] && git_pull_default_branch "$HOME/.oh-my-zsh" "Oh My Zsh"
    [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/.git" ]] && \
        git_pull_default_branch "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
    [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/.git" ]] && \
        git_pull_default_branch "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" "zsh-completions"
    [[ -d "$HOME/.zsh/pure/.git" ]] && git_pull_default_branch "$HOME/.zsh/pure" "Pure prompt"
}

check_node_updates() {
    is_component_installed "node" || return 1
    git_repo_has_updates "$HOME/.nodenv" && return 0
    git_repo_has_updates "$HOME/.nodenv/plugins/node-build" && return 0
    return 1
}

upgrade_node() {
    is_component_installed "node" || return
    [[ -d "$HOME/.nodenv/.git" ]] && git_pull_default_branch "$HOME/.nodenv" "nodenv"
    [[ -d "$HOME/.nodenv/plugins/node-build/.git" ]] && \
        git_pull_default_branch "$HOME/.nodenv/plugins/node-build" "node-build"
}

check_ruby_updates() {
    is_component_installed "ruby" || return 1
    git_repo_has_updates "$HOME/.rbenv" && return 0
    git_repo_has_updates "$HOME/.rbenv/plugins/ruby-build" && return 0
    return 1
}

upgrade_ruby() {
    is_component_installed "ruby" || return
    [[ -d "$HOME/.rbenv/.git" ]] && git_pull_default_branch "$HOME/.rbenv" "rbenv"
    [[ -d "$HOME/.rbenv/plugins/ruby-build/.git" ]] && \
        git_pull_default_branch "$HOME/.rbenv/plugins/ruby-build" "ruby-build"
    command -v gem >/dev/null 2>&1 && {
        gem update --system --silent 2>/dev/null || true
        gem update --silent 2>/dev/null || true
    }
}

# ============================================================================
# Main command
# ============================================================================

cmd_upgrade() {
    local skip_prompt=false

    for arg in "$@"; do
        case "$arg" in
            -y|--yes) skip_prompt=true ;;
        esac
    done

    log_step "Checking for upgrades"
    echo

    # Collect what needs upgrading with version info
    local upgrades=()
    local has_system_updates=false

    # Check system packages
    case "$PKG_MGR" in
        apt)
            maybe_sudo apt update -qq 2>/dev/null
            local apt_updates
            apt_updates=$(get_apt_upgradable)
            if [[ -n "$apt_updates" ]]; then
                has_system_updates=true
                upgrades+=("system (apt):")
                while IFS= read -r line; do
                    [[ -n "$line" ]] && upgrades+=("  $line")
                done <<< "$apt_updates"
            fi
            ;;
        brew)
            brew update --quiet 2>/dev/null
            local brew_updates
            brew_updates=$(get_brew_upgradable)
            if [[ -n "$brew_updates" ]]; then
                has_system_updates=true
                upgrades+=("system (brew):")
                while IFS= read -r line; do
                    [[ -n "$line" ]] && upgrades+=("  $line")
                done <<< "$brew_updates"
            fi
            ;;
        dnf|pacman)
            # These don't have easy ways to list upgradable without running upgrade
            has_system_updates=true
            upgrades+=("system ($PKG_MGR)")
            ;;
    esac

    # Check component-specific updates
    if check_zsh_updates; then
        upgrades+=("zsh (oh-my-zsh, plugins, pure prompt)")
    fi
    if check_node_updates; then
        upgrades+=("node (nodenv, node-build)")
    fi
    if check_ruby_updates; then
        upgrades+=("ruby (rbenv, ruby-build, gems)")
    fi

    # Nothing to upgrade?
    if [[ ${#upgrades[@]} -eq 0 ]]; then
        log_success "Everything is up to date"
        return 0
    fi

    # Show what will be upgraded
    echo "The following will be upgraded:"
    for item in "${upgrades[@]}"; do
        echo "  $item"
    done
    echo

    # Prompt for confirmation
    if [[ "$skip_prompt" != "true" ]] && [[ "$DRY_RUN" != "true" ]] && [[ -t 0 ]]; then
        printf "Proceed? [y/N] "
        read -r answer
        [[ "$answer" =~ ^[Yy]$ ]] || { log_info "Aborted"; return 0; }
        echo
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would upgrade the above"
        return 0
    fi

    # Run upgrades
    local upgraded=()

    if [[ "$has_system_updates" == "true" ]]; then
        log_step "Upgrading system packages"
        upgrade_system_packages
        upgraded+=("system")
        echo
    fi

    if check_zsh_updates 2>/dev/null; then
        log_info "Upgrading zsh components..."
        upgrade_zsh
        upgraded+=("zsh")
    fi

    if check_node_updates 2>/dev/null; then
        log_info "Upgrading node components..."
        upgrade_node
        upgraded+=("node")
    fi

    if check_ruby_updates 2>/dev/null; then
        log_info "Upgrading ruby components..."
        upgrade_ruby
        upgraded+=("ruby")
    fi

    echo
    log_step "Upgrade Complete"
    [[ ${#upgraded[@]} -gt 0 ]] && log_success "Upgraded: ${upgraded[*]}"

    # Remind about manual upgrades
    if is_component_installed "bun"; then
        log_info "To upgrade bun: bun upgrade"
    fi
}
