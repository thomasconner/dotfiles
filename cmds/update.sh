#!/usr/bin/env bash

# ctdev update - Update system and installed components

# Detect OS and package manager
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

# ============================================================================
# System Update Functions
# ============================================================================

update_system_packages() {
    log_step "Updating System Packages"

    case "$PKG_MGR" in
        apt)
            log_info "Updating apt package lists..."
            run_cmd maybe_sudo apt update

            log_info "Upgrading packages..."
            run_cmd maybe_sudo apt full-upgrade -y --fix-missing

            log_info "Removing unnecessary packages..."
            run_cmd maybe_sudo apt autoremove -y

            log_info "Cleaning package cache..."
            run_cmd maybe_sudo apt autoclean
            ;;
        dnf)
            log_info "Upgrading packages with dnf..."
            run_cmd maybe_sudo dnf upgrade -y

            log_info "Removing unnecessary packages..."
            run_cmd maybe_sudo dnf autoremove -y
            ;;
        pacman)
            log_info "Updating package database and upgrading with pacman..."
            run_cmd maybe_sudo pacman -Syu --noconfirm

            log_info "Removing orphaned packages..."
            run_cmd maybe_sudo pacman -Rns "$(pacman -Qtdq)" --noconfirm 2>/dev/null || true
            ;;
        brew)
            log_info "Updating Homebrew..."
            run_cmd brew update

            log_info "Upgrading packages..."
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
            log_info "Updating FreeBSD packages..."
            run_cmd maybe_sudo pkg update
            run_cmd maybe_sudo pkg upgrade -y
            run_cmd maybe_sudo pkg autoremove -y
            ;;
        *)
            log_warning "Unknown package manager: $PKG_MGR"
            log_warning "Skipping system package updates"
            ;;
    esac

    log_success "System packages updated"
}

update_macos_software() {
    if [[ "$OS" != "macos" ]]; then
        return
    fi

    log_step "Checking macOS Software Updates"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would check: softwareupdate -l"
    else
        log_info "Checking for macOS updates..."
        softwareupdate -l 2>&1 || true
        log_info "To install macOS updates, run: sudo softwareupdate -ia"
    fi

    log_success "macOS software update check complete"
}

update_firmware() {
    if [[ "$OS" == "macos" ]]; then
        return
    fi

    log_step "Checking Firmware Updates"

    if ! command -v fwupdmgr >/dev/null 2>&1; then
        log_info "fwupdmgr not installed, skipping firmware updates"
        return
    fi

    log_info "Refreshing firmware metadata..."
    run_cmd fwupdmgr refresh --force 2>/dev/null || log_warning "Could not refresh firmware metadata"

    log_info "Checking for available firmware updates..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would check: fwupdmgr get-updates"
    else
        if fwupdmgr get-updates 2>/dev/null; then
            log_info "Firmware updates available, installing..."
            run_cmd fwupdmgr update -y
            log_success "Firmware updated"
        else
            log_success "Firmware is up to date"
        fi
    fi
}

# ============================================================================
# Component Update Functions
# ============================================================================

update_zsh() {
    log_step "Updating zsh components"

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
        log_info "Updating Oh My Zsh..."
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
            log_info "Updating $plugin_name..."

            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] Would update: $plugin_dir"
            else
                git_pull_default_branch "$plugin_dir" "$plugin_name"
            fi
        fi
    done

    # Pure prompt
    if [[ -d "$HOME/.zsh/pure/.git" ]]; then
        log_info "Updating Pure prompt..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update Pure prompt"
        else
            git_pull_default_branch "$HOME/.zsh/pure" "Pure prompt"
        fi
    fi

    log_success "Zsh components updated"
}

update_node() {
    log_step "Updating node components"

    # Update nodenv if installed via git (not Homebrew)
    if [[ -d "$HOME/.nodenv/.git" ]]; then
        log_info "Updating nodenv..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update nodenv and node-build"
        else
            git_pull_default_branch "$HOME/.nodenv" "nodenv"

            if [[ -d "$HOME/.nodenv/plugins/node-build/.git" ]]; then
                git_pull_default_branch "$HOME/.nodenv/plugins/node-build" "node-build"
            fi
        fi
    elif command -v nodenv >/dev/null 2>&1; then
        log_info "nodenv installed via package manager, updated via system packages"
    fi

    # Update npm packages
    if command -v npm >/dev/null 2>&1; then
        log_info "Updating global npm packages..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would run: npm update -g"
        else
            npm update -g 2>/dev/null || log_warning "Could not update npm global packages"
        fi
    fi

    log_success "Node.js components updated"
}

update_ruby() {
    log_step "Updating ruby components"

    # Update rbenv if installed via git (not Homebrew)
    if [[ -d "$HOME/.rbenv/.git" ]]; then
        log_info "Updating rbenv..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would update rbenv and ruby-build"
        else
            git_pull_default_branch "$HOME/.rbenv" "rbenv"

            if [[ -d "$HOME/.rbenv/plugins/ruby-build/.git" ]]; then
                git_pull_default_branch "$HOME/.rbenv/plugins/ruby-build" "ruby-build"
            fi
        fi
    elif command -v rbenv >/dev/null 2>&1; then
        log_info "rbenv installed via package manager, updated via system packages"
    fi

    # Update gems
    if command -v gem >/dev/null 2>&1; then
        log_info "Updating RubyGems system..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would run: gem update --system"
        else
            gem update --system 2>/dev/null || log_warning "Could not update RubyGems system"
            gem update 2>/dev/null || log_warning "Could not update gems"
        fi
    fi

    log_success "Ruby components updated"
}

update_cli() {
    log_step "Updating cli components"

    # Update GitHub CLI extensions
    if command -v gh >/dev/null 2>&1; then
        log_info "Updating GitHub CLI extensions..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Would run: gh extension upgrade --all"
        else
            gh extension upgrade --all 2>/dev/null || log_info "No gh extensions to update"
        fi
    fi

    # On macOS, CLI tools are updated via brew upgrade (already done in system packages)
    if [[ "$OS" == "macos" ]]; then
        log_info "CLI tools updated via Homebrew (see system packages)"
    fi

    log_success "CLI tools updated"
}

# ============================================================================
# Component Update Support
# ============================================================================

# Components that have meaningful updates (beyond system package manager)
UPDATABLE_COMPONENTS="zsh node ruby cli"

has_update_support() {
    local component="$1"
    [[ " $UPDATABLE_COMPONENTS " == *" $component "* ]]
}

run_component_update() {
    local component="$1"
    case "$component" in
        zsh)  update_zsh ;;
        node) update_node ;;
        ruby) update_ruby ;;
        cli)  update_cli ;;
    esac
}

# ============================================================================
# Main command
# ============================================================================

cmd_update() {
    local components=()
    local skip_system=false

    # Parse subcommand arguments
    for arg in "$@"; do
        case "$arg" in
            -h|--help|-v|--verbose|-n|--dry-run)
                # Already handled by main dispatcher
                ;;
            --skip-system)
                skip_system=true
                ;;
            *)
                components+=("$arg")
                ;;
        esac
    done

    # If no components specified, update all installed components
    if [[ ${#components[@]} -eq 0 ]]; then
        log_step "Updating system and installed components"
    else
        # Validate specified components
        if ! validate_components "${components[@]}"; then
            return 1
        fi
        log_step "Updating components: ${components[*]}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    log_info "Detected OS: $OS"
    log_info "Package manager: $PKG_MGR"
    echo

    # Run system updates first (unless skipped or specific components requested)
    if [[ "$skip_system" == "true" ]]; then
        log_info "Skipping system package updates (--skip-system)"
        echo
    elif [[ ${#components[@]} -eq 0 ]]; then
        update_system_packages
        echo
        update_macos_software
        echo
        update_firmware
        echo
    fi

    local updated=()
    local skipped=()

    # Determine which components to update
    local targets=()
    if [[ ${#components[@]} -gt 0 ]]; then
        targets=("${components[@]}")
    else
        # Update all installed components that have update support
        for component in $UPDATABLE_COMPONENTS; do
            if is_component_installed "$component"; then
                targets+=("$component")
            fi
        done
    fi

    # Run updates for each component
    for component in "${targets[@]}"; do
        if ! is_component_installed "$component"; then
            log_info "$component: Not installed, skipping"
            skipped+=("$component")
            continue
        fi

        if has_update_support "$component"; then
            run_component_update "$component"
            updated+=("$component")
        else
            log_info "$component: No update needed (one-time setup)"
            skipped+=("$component")
        fi

        echo ""
    done

    # Summary
    log_step "Update Complete"

    if [[ ${#updated[@]} -gt 0 ]]; then
        log_success "Updated: ${updated[*]}"
    fi

    if [[ ${#skipped[@]} -gt 0 ]]; then
        log_info "Skipped: ${skipped[*]}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry-run. Run without --dry-run to apply changes."
    else
        log_info "You may need to restart your shell for some changes to take effect"
    fi

    return 0
}
