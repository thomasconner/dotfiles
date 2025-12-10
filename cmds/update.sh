#!/usr/bin/env bash

# ctdev update - Update dotfiles components

# Detect OS and package manager
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

# ============================================================================
# Update Functions
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
            if [[ "$DRY_RUN" == "false" ]]; then
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
        log_debug "[DRY-RUN] Would check: softwareupdate -l"
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
        log_debug "[DRY-RUN] Would check: fwupdmgr get-updates"
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

update_zsh() {
    log_step "Updating Zsh Components"

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
        log_info "Updating Oh My Zsh..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY-RUN] Would update Oh My Zsh"
        else
            git -C "$HOME/.oh-my-zsh" pull --ff-only origin master || log_warning "Could not update Oh My Zsh"
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
                log_debug "[DRY-RUN] Would update: $plugin_dir"
            else
                # Try master first, then main
                if ! git -C "$plugin_dir" pull --ff-only origin master 2>/dev/null; then
                    git -C "$plugin_dir" pull --ff-only origin main 2>/dev/null || \
                    log_warning "Could not update $plugin_name"
                fi
            fi
        fi
    done

    # Pure prompt
    if [[ -d "$HOME/.zsh/pure/.git" ]]; then
        log_info "Updating Pure prompt..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY-RUN] Would update Pure prompt"
        else
            git -C "$HOME/.zsh/pure" pull --ff-only origin main || \
            log_warning "Could not update Pure prompt"
        fi
    fi

    log_success "Zsh components updated"
}

update_node() {
    log_step "Updating Node.js Components"

    # Update nodenv if installed via git (not Homebrew)
    if [[ -d "$HOME/.nodenv/.git" ]]; then
        log_info "Updating nodenv..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY-RUN] Would update nodenv and node-build"
        else
            git -C "$HOME/.nodenv" pull --ff-only origin master || \
            log_warning "Could not update nodenv"

            if [[ -d "$HOME/.nodenv/plugins/node-build/.git" ]]; then
                git -C "$HOME/.nodenv/plugins/node-build" pull --ff-only origin master || \
                log_warning "Could not update node-build"
            fi
        fi
    elif command -v nodenv >/dev/null 2>&1; then
        log_info "nodenv installed via package manager, updated via system packages"
    fi

    # Update npm packages
    if command -v npm >/dev/null 2>&1; then
        log_info "Updating global npm packages..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY-RUN] Would run: npm update -g"
        else
            npm update -g 2>/dev/null || log_warning "Could not update npm global packages"
        fi
    fi

    log_success "Node.js components updated"
}

update_ruby() {
    log_step "Updating Ruby Components"

    # Update rbenv if installed via git (not Homebrew)
    if [[ -d "$HOME/.rbenv/.git" ]]; then
        log_info "Updating rbenv..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY-RUN] Would update rbenv and ruby-build"
        else
            git -C "$HOME/.rbenv" pull --ff-only origin master || \
            log_warning "Could not update rbenv"

            if [[ -d "$HOME/.rbenv/plugins/ruby-build/.git" ]]; then
                git -C "$HOME/.rbenv/plugins/ruby-build" pull --ff-only origin master || \
                log_warning "Could not update ruby-build"
            fi
        fi
    elif command -v rbenv >/dev/null 2>&1; then
        log_info "rbenv installed via package manager, updated via system packages"
    fi

    # Update gems
    if command -v gem >/dev/null 2>&1; then
        log_info "Updating RubyGems system..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY-RUN] Would run: gem update --system"
        else
            gem update --system 2>/dev/null || log_warning "Could not update RubyGems system"
            gem update 2>/dev/null || log_warning "Could not update gems"
        fi
    fi

    log_success "Ruby components updated"
}

update_cli() {
    log_step "Updating CLI Tools"

    # For macOS with Homebrew, CLI tools are updated via brew upgrade
    if [[ "$OS" == "macos" ]]; then
        log_info "CLI tools updated via Homebrew (see system packages update)"
        log_success "CLI tools checked"
        return
    fi

    # Update GitHub CLI on Linux
    if command -v gh >/dev/null 2>&1; then
        log_info "Updating GitHub CLI..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY-RUN] Would update: gh"
        else
            case "$PKG_MGR" in
                apt)
                    maybe_sudo apt update && maybe_sudo apt install -y gh
                    ;;
                dnf)
                    maybe_sudo dnf upgrade -y gh
                    ;;
                *)
                    log_info "Manual update required for gh on $OS"
                    ;;
            esac
        fi
    fi

    # Show versions for other tools
    if command -v kubectl >/dev/null 2>&1; then
        log_info "Current kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    fi

    if command -v doctl >/dev/null 2>&1; then
        log_info "Current doctl: $(doctl version)"
    fi

    if command -v helm >/dev/null 2>&1; then
        log_info "Current Helm: $(helm version --short 2>/dev/null || helm version)"
    fi

    log_success "CLI tools checked"
}

# ============================================================================
# Component mapping
# ============================================================================

get_update_function() {
    local component="$1"
    case "$component" in
        system) echo "update_system_packages" ;;
        zsh)    echo "update_zsh" ;;
        node)   echo "update_node" ;;
        ruby)   echo "update_ruby" ;;
        cli)    echo "update_cli" ;;
        *)      echo "" ;;
    esac
}

# ============================================================================
# Main command
# ============================================================================

cmd_update() {
    local components=("$@")

    log_step "ctdev update"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi
    log_info "Detected OS: $OS"
    log_info "Package manager: $PKG_MGR"
    echo

    # If no components specified, update all
    if [[ ${#components[@]} -eq 0 ]]; then
        log_info "Updating all components..."
        echo

        update_system_packages
        echo
        update_macos_software
        echo
        update_firmware
        echo
        update_zsh
        echo
        update_node
        echo
        update_ruby
        echo
        update_cli
        echo
    else
        # Update specified components
        for component in "${components[@]}"; do
            local update_fn
            update_fn=$(get_update_function "$component")

            if [[ -z "$update_fn" ]]; then
                log_warning "No update function for component: $component"
                continue
            fi

            "$update_fn"
            echo
        done
    fi

    log_step "Update Complete!"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry-run. Run without --dry-run to apply updates."
    else
        log_success "All updates completed successfully"
        log_info "You may need to restart your shell for some changes to take effect"
    fi
}
