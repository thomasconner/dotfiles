#!/usr/bin/env bash

# ctdev upgrade - Upgrade system packages and components

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
# Additional upgrade sources
# ============================================================================

check_softwareupdate_available() {
    [[ "$OS" == "macos" ]] || return 1
    local updates
    updates=$(softwareupdate --list 2>&1)
    echo "$updates" | grep -q "Software Update found" && return 0
    return 1
}

check_flatpak_updates() {
    command -v flatpak >/dev/null 2>&1 || return 1
    local updates
    updates=$(flatpak remote-ls --updates 2>/dev/null)
    [[ -n "$updates" ]]
}

# Whether NVIDIA modules need re-signing after a system upgrade
needs_nvidia_signing() {
    [[ "$OS" != "macos" ]] || return 1
    source "$DOTFILES_ROOT/lib/gpu.sh"
    is_secure_boot_enabled || return 1
    mok_key_exists || return 1
    local modules
    modules=$(find_nvidia_modules)
    [[ -n "$modules" ]] || return 1
    # Check if any modules are unsigned
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue
        is_module_signed "$module" || return 0
    done <<< "$modules"
    return 1
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
    local check_only=false
    local do_refresh_keys=false
    local key_filter=()
    local collecting_keys=false

    for arg in "$@"; do
        if [[ "$collecting_keys" == "true" ]]; then
            case "$arg" in
                -*) collecting_keys=false ;;
                *)
                    key_filter+=("$arg")
                    continue
                    ;;
            esac
        fi
        case "$arg" in
            -y|--yes) skip_prompt=true ;;
            --check) check_only=true ;;
            --refresh-keys)
                do_refresh_keys=true
                collecting_keys=true
                ;;
        esac
    done

    # Refresh GPG keys if requested (apt only)
    if [[ "$do_refresh_keys" == "true" ]]; then
        if [[ "$PKG_MGR" == "apt" ]]; then
            source "$DOTFILES_ROOT/lib/keys.sh"
            log_step "Refreshing APT repository keys"
            refresh_keys "${key_filter[@]}" || true
            echo
        else
            log_warning "--refresh-keys is only supported on apt-based systems"
        fi
    fi

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

    # Check macOS softwareupdate
    if check_softwareupdate_available 2>/dev/null; then
        upgrades+=("macOS software updates")
    fi

    # Check flatpak
    if check_flatpak_updates 2>/dev/null; then
        upgrades+=("flatpak packages")
    fi

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

    # Bun: no reliable pre-check, always show if installed
    if is_component_installed "bun"; then
        upgrades+=("bun")
    fi

    # Check NVIDIA module signing
    local needs_nvidia=false
    if needs_nvidia_signing 2>/dev/null; then
        needs_nvidia=true
        upgrades+=("nvidia module signing")
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

    # --check: list only, don't install
    if [[ "$check_only" == "true" ]]; then
        log_info "Run 'ctdev upgrade' to install these updates"
        return 0
    fi

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

    # 1. System packages
    if [[ "$has_system_updates" == "true" ]]; then
        log_step "Upgrading system packages"
        upgrade_system_packages
        upgraded+=("system")
        echo
    fi

    # 2. macOS softwareupdate
    if [[ "$OS" == "macos" ]]; then
        if check_softwareupdate_available 2>/dev/null; then
            log_step "Installing macOS software updates"
            softwareupdate --install --all --agree-to-license 2>&1 || \
                log_warning "Some macOS updates may require a restart"
            upgraded+=("macos-softwareupdate")
            echo
        fi
    fi

    # 3. Flatpak
    if command -v flatpak >/dev/null 2>&1; then
        if check_flatpak_updates 2>/dev/null; then
            log_step "Upgrading flatpak packages"
            run_cmd flatpak update -y
            upgraded+=("flatpak")
            echo
        fi
    fi

    # 4. Component upgrades
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

    # 5. Bun
    if is_component_installed "bun"; then
        log_info "Upgrading bun..."
        bun upgrade 2>/dev/null || log_warning "bun upgrade failed"
        upgraded+=("bun")
    fi

    # 6. NVIDIA module re-signing
    if [[ "$needs_nvidia" == "true" ]]; then
        log_step "Re-signing NVIDIA kernel modules"
        source "$DOTFILES_ROOT/lib/gpu.sh"
        sign_nvidia_modules || log_warning "NVIDIA module signing failed"
        upgraded+=("nvidia-signing")
        echo
    fi

    echo
    log_step "Upgrade Complete"
    [[ ${#upgraded[@]} -gt 0 ]] && log_success "Upgraded: ${upgraded[*]}"
}
