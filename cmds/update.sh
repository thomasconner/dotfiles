#!/usr/bin/env bash

# ctdev update - Refresh package metadata (does not upgrade)

OS=$(detect_os)
PKG_MGR=$(get_package_manager)

cmd_update() {
    local do_refresh_keys=false
    local key_filter=()

    for arg in "$@"; do
        case "$arg" in
            --refresh-keys) do_refresh_keys=true ;;
            *) key_filter+=("$arg") ;;
        esac
    done

    log_step "Updating package sources"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    log_info "OS: $OS"
    log_info "Package manager: $PKG_MGR"
    echo

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

    # Update system package lists
    case "$PKG_MGR" in
        apt)
            log_info "Updating apt package lists..."
            run_cmd maybe_sudo apt update
            ;;
        dnf)
            log_info "Refreshing dnf metadata..."
            run_cmd maybe_sudo dnf check-update || true
            ;;
        pacman)
            log_info "Synchronizing pacman database..."
            run_cmd maybe_sudo pacman -Sy
            ;;
        brew)
            log_info "Updating Homebrew..."
            run_cmd brew update
            ;;
        pkg)
            log_info "Updating FreeBSD package catalog..."
            run_cmd maybe_sudo pkg update
            ;;
        *)
            log_warning "Unknown package manager: $PKG_MGR"
            ;;
    esac

    echo

    # Fetch updates for version managers (without pulling)
    local updates_available=()

    if [[ -d "$HOME/.nodenv/.git" ]]; then
        log_info "Checking nodenv for updates..."
        if git -C "$HOME/.nodenv" fetch --quiet 2>/dev/null; then
            local behind
            behind=$(git -C "$HOME/.nodenv" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || behind=0
            if [[ "$behind" -gt 0 ]]; then
                updates_available+=("nodenv: $behind commits behind")
            fi
        fi
    fi

    if [[ -d "$HOME/.rbenv/.git" ]]; then
        log_info "Checking rbenv for updates..."
        if git -C "$HOME/.rbenv" fetch --quiet 2>/dev/null; then
            local behind
            behind=$(git -C "$HOME/.rbenv" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || behind=0
            if [[ "$behind" -gt 0 ]]; then
                updates_available+=("rbenv: $behind commits behind")
            fi
        fi
    fi

    if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
        log_info "Checking Oh My Zsh for updates..."
        if git -C "$HOME/.oh-my-zsh" fetch --quiet 2>/dev/null; then
            local behind
            behind=$(git -C "$HOME/.oh-my-zsh" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || behind=0
            if [[ "$behind" -gt 0 ]]; then
                updates_available+=("oh-my-zsh: $behind commits behind")
            fi
        fi
    fi

    echo
    log_step "Update Complete"

    if [[ ${#updates_available[@]} -gt 0 ]]; then
        echo
        log_info "Updates available:"
        for update in "${updates_available[@]}"; do
            echo "  $update"
        done
    fi

    echo
    log_info "Run 'ctdev upgrade' to upgrade components"

    return 0
}
