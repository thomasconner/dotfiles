#!/usr/bin/env bash

# ctdev install - Install dotfiles components

# Detect OS and package manager
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

# ============================================================================
# Update Detection Functions
# ============================================================================

# Check if a git repo is behind its remote
# Returns 0 if updates available, 1 if up to date or not a git repo
git_repo_has_updates() {
    local repo_path="$1"

    if [[ ! -d "$repo_path/.git" ]]; then
        return 1
    fi

    # Fetch quietly and check if behind
    if git -C "$repo_path" fetch --quiet 2>/dev/null; then
        local behind
        behind=$(git -C "$repo_path" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || return 1
        if [[ "$behind" -gt 0 ]]; then
            return 0
        fi
    fi

    return 1
}

# Check if a component has updates available
# Sets UPDATES_AVAILABLE array with descriptions
check_component_updates() {
    local component="$1"
    UPDATES_AVAILABLE=()

    case "$component" in
        zsh)
            git_repo_has_updates "$HOME/.oh-my-zsh" && UPDATES_AVAILABLE+=("Oh My Zsh")
            git_repo_has_updates "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" && UPDATES_AVAILABLE+=("zsh-autosuggestions")
            git_repo_has_updates "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" && UPDATES_AVAILABLE+=("zsh-completions")
            git_repo_has_updates "$HOME/.zsh/pure" && UPDATES_AVAILABLE+=("Pure prompt")
            ;;
        node)
            git_repo_has_updates "$HOME/.nodenv" && UPDATES_AVAILABLE+=("nodenv")
            git_repo_has_updates "$HOME/.nodenv/plugins/node-build" && UPDATES_AVAILABLE+=("node-build")
            ;;
        ruby)
            git_repo_has_updates "$HOME/.rbenv" && UPDATES_AVAILABLE+=("rbenv")
            git_repo_has_updates "$HOME/.rbenv/plugins/ruby-build" && UPDATES_AVAILABLE+=("ruby-build")
            ;;
        cli)
            # CLI tools update via package manager or gh extensions
            # Can't easily detect without running update
            ;;
    esac

    [[ ${#UPDATES_AVAILABLE[@]} -gt 0 ]]
}

# Components that have meaningful updates (beyond system package manager)
UPDATABLE_COMPONENTS="zsh node ruby cli"

has_update_support() {
    local component="$1"
    [[ " $UPDATABLE_COMPONENTS " == *" $component "* ]]
}

# ============================================================================
# Main command
# ============================================================================

cmd_install() {
    local components=()

    # Parse subcommand arguments, filtering out flags that were already processed
    for arg in "$@"; do
        case "$arg" in
            -h|--help|-v|--verbose|-n|--dry-run|-f|--force)
                # Already handled by main dispatcher
                ;;
            --skip-system)
                # Deprecated flag - install no longer updates system packages
                log_warning "--skip-system is deprecated (install no longer updates system packages)"
                log_info "Use 'ctdev update' to update system packages"
                ;;
            *)
                components+=("$arg")
                ;;
        esac
    done

    # If no components specified, install all in default order
    if [[ ${#components[@]} -eq 0 ]]; then
        # shellcheck disable=SC2206
        components=($DEFAULT_INSTALL_ORDER)
        log_step "Installing all components"
    else
        # Validate specified components
        if ! validate_components "${components[@]}"; then
            return 1
        fi
        log_step "Installing components: ${components[*]}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    if [[ "${FORCE:-false}" == "true" ]]; then
        log_warning "FORCE MODE: Re-running install scripts for all specified components"
    fi

    log_info "Detected OS: $OS"
    log_info "Package manager: $PKG_MGR"
    echo

    local failed=()
    local installed=()
    local already_installed=()
    local components_with_updates=()

    for component in "${components[@]}"; do
        local script
        script=$(get_component_install_script "$component")

        if [[ ! -f "$script" ]]; then
            log_warning "Install script not found for $component: $script"
            failed+=("$component")
            continue
        fi

        if [[ "${FORCE:-false}" != "true" ]] && is_component_installed "$component"; then
            # Component already installed - check for updates
            log_step "Checking $component"
            log_info "$component is already installed"

            if has_update_support "$component"; then
                if check_component_updates "$component"; then
                    log_info "Updates available: ${UPDATES_AVAILABLE[*]}"
                    components_with_updates+=("$component")
                else
                    log_info "Up to date"
                fi
            fi
            already_installed+=("$component")
        else
            # Component not installed - run install script
            log_step "Installing $component"

            # Run the install script, passing through environment (including DRY_RUN)
            if bash "$script"; then
                installed+=("$component")
                # Create installation marker for tracking
                create_install_marker "$component"
            else
                log_error "Failed to install $component"
                failed+=("$component")
            fi
        fi

        echo ""
    done

    # Summary
    log_step "Complete"

    if [[ ${#installed[@]} -gt 0 ]]; then
        log_success "Installed: ${installed[*]}"
    fi

    if [[ ${#already_installed[@]} -gt 0 ]]; then
        log_info "Already installed: ${already_installed[*]}"
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed: ${failed[*]}"
    fi

    # Prompt about updates if any are available
    if [[ ${#components_with_updates[@]} -gt 0 ]]; then
        echo
        log_warning "Updates available for: ${components_with_updates[*]}"

        # Only prompt if interactive
        if [[ -t 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
            printf "Would you like to update these components now? [y/N] "
            if read -r -t 30 answer && [[ "$answer" =~ ^[Yy]$ ]]; then
                echo
                # Source and run update command for these components
                source "${DOTFILES_ROOT}/cmds/update.sh"
                cmd_update "${components_with_updates[@]}"
            else
                log_info "Run 'ctdev update' later to update these components"
            fi
        else
            log_info "Run 'ctdev update' to update these components"
        fi
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry-run. Run without --dry-run to apply changes."
    elif [[ ${#installed[@]} -gt 0 ]]; then
        log_info "You may need to restart your shell for some changes to take effect"
    fi

    return 0
}
