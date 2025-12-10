#!/usr/bin/env bash
#
# update.sh - Update system packages, dotfiles components, and development tools
#
# This script provides comprehensive updates for:
# - System packages (apt, dnf, pacman, brew, etc.)
# - Version managers (nodenv, rbenv)
# - Node.js and Ruby to latest configured versions
# - Oh My Zsh and plugins
# - Git repositories (Pure prompt, etc.)
# - CLI tools (gh, kubectl, doctl, helm)
# - Firmware updates (fwupd) - Linux only
# - macOS software updates
#
# Usage:
#   ./update.sh [OPTIONS]
#
# Options:
#   --dry-run, -n    Preview what would be updated without making changes
#   --verbose, -v    Enable detailed output and bash debugging
#   --version        Display version information
#   --help, -h       Show this help message
#

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities
# shellcheck source=scripts/utils.sh
source "${SCRIPT_DIR}/scripts/utils.sh"

# Parse command line arguments
DRY_RUN=false
VERBOSE=false

show_help() {
    cat << EOF
update.sh - Update system packages and dotfiles components

Usage:
    ./update.sh [OPTIONS]

Options:
    --dry-run, -n    Preview what would be updated without making changes
    --verbose, -v    Enable detailed output and bash debugging
    --version        Display version information
    --help, -h       Show this help message

This script updates:
    - System packages (apt, dnf, pacman, brew, etc.)
    - Version managers (nodenv, rbenv)
    - Node.js and Ruby to latest configured versions
    - Oh My Zsh and plugins
    - Git repositories and CLI tools
    - Firmware (fwupd) - Linux only
    - macOS software updates

EOF
}

show_version() {
    if [[ -f "${SCRIPT_DIR}/VERSION" ]]; then
        local version
        version=$(cat "${SCRIPT_DIR}/VERSION")
        echo "dotfiles update script v${version}"
    else
        echo "dotfiles update script (version unknown)"
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --version)
            show_version
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Enable verbose mode if requested
if [[ "$VERBOSE" == "true" ]]; then
    set -x
fi

# Detect OS and package manager
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

log_step "Dotfiles Update Script"
if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "DRY-RUN MODE: No changes will be made"
fi
log_info "Detected OS: $OS"
log_info "Package manager: $PKG_MGR"
echo

# Function to run commands with dry-run support
run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would run: $*"
    else
        "$@"
    fi
}

# ============================================================================
# System Package Updates
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
            # Some casks may fail (disabled, requires password, etc.) - continue anyway
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
    echo
}

# ============================================================================
# macOS Software Updates
# ============================================================================

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
    echo
}

# ============================================================================
# Firmware Updates (Linux only)
# ============================================================================

update_firmware() {
    if [[ "$OS" == "macos" ]]; then
        # macOS handles firmware through system updates
        return
    fi

    log_step "Checking Firmware Updates"

    if ! command -v fwupdmgr >/dev/null 2>&1; then
        log_info "fwupdmgr not installed, skipping firmware updates"
        echo
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
    echo
}

# ============================================================================
# Oh My Zsh Updates
# ============================================================================

update_oh_my_zsh() {
    log_step "Updating Oh My Zsh"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh not installed, skipping"
        echo
        return
    fi

    log_info "Updating Oh My Zsh..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would run: omz update"
    else
        # Disable automatic update check and run update
        DISABLE_UPDATE_PROMPT=true
        cd "$HOME/.oh-my-zsh" && git pull --ff-only origin master 2>/dev/null || log_warning "Could not update Oh My Zsh"
    fi

    log_success "Oh My Zsh updated"
    echo
}

# ============================================================================
# Zsh Plugin Updates
# ============================================================================

update_zsh_plugins() {
    log_step "Updating Zsh Plugins"

    local plugins=(
        "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
        "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
    )

    for plugin_dir in "${plugins[@]}"; do
        if [[ -d "$plugin_dir" ]]; then
            local plugin_name
            plugin_name=$(basename "$plugin_dir")
            log_info "Updating $plugin_name..."

            if [[ "$DRY_RUN" == "true" ]]; then
                log_debug "[DRY-RUN] Would update: $plugin_dir"
            else
                cd "$plugin_dir" && git pull --ff-only origin master 2>/dev/null || \
                cd "$plugin_dir" && git pull --ff-only origin main 2>/dev/null || \
                log_warning "Could not update $plugin_name"
            fi
        fi
    done

    log_success "Zsh plugins updated"
    echo
}

# ============================================================================
# Pure Prompt Update
# ============================================================================

update_pure_prompt() {
    log_step "Updating Pure Prompt"

    if [[ ! -d "$HOME/.zsh/pure" ]]; then
        log_info "Pure prompt not installed, skipping"
        echo
        return
    fi

    log_info "Updating Pure prompt..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would update: $HOME/.zsh/pure"
    else
        cd "$HOME/.zsh/pure" && git pull --ff-only origin main 2>/dev/null || \
        log_warning "Could not update Pure prompt"
    fi

    log_success "Pure prompt updated"
    echo
}

# ============================================================================
# nodenv and Node.js Updates
# ============================================================================

update_nodenv() {
    log_step "Updating nodenv and Node.js"

    if [[ ! -d "$HOME/.nodenv" ]]; then
        log_info "nodenv not installed, skipping"
        echo
        return
    fi

    log_info "Updating nodenv..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would update nodenv and node-build"
    else
        cd "$HOME/.nodenv" && git pull --ff-only origin master 2>/dev/null || \
        log_warning "Could not update nodenv"

        if [[ -d "$HOME/.nodenv/plugins/node-build" ]]; then
            cd "$HOME/.nodenv/plugins/node-build" && git pull --ff-only origin master 2>/dev/null || \
            log_warning "Could not update node-build"
        fi
    fi

    log_info "Checking for Node.js updates..."
    if command -v nodenv >/dev/null 2>&1 && [[ "$DRY_RUN" == "false" ]]; then
        local current_version
        current_version=$(nodenv version-name 2>/dev/null || echo "none")
        log_info "Current Node.js version: $current_version"
        log_info "Run 'nodenv install -l' to see available versions"
        log_info "Run 'nodenv install <version> && nodenv global <version>' to upgrade"
    fi

    log_success "nodenv updated"
    echo
}

# ============================================================================
# rbenv and Ruby Updates
# ============================================================================

update_rbenv() {
    log_step "Updating rbenv and Ruby"

    if [[ ! -d "$HOME/.rbenv" ]]; then
        log_info "rbenv not installed, skipping"
        echo
        return
    fi

    log_info "Updating rbenv..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would update rbenv and ruby-build"
    else
        cd "$HOME/.rbenv" && git pull --ff-only origin master 2>/dev/null || \
        log_warning "Could not update rbenv"

        if [[ -d "$HOME/.rbenv/plugins/ruby-build" ]]; then
            cd "$HOME/.rbenv/plugins/ruby-build" && git pull --ff-only origin master 2>/dev/null || \
            log_warning "Could not update ruby-build"
        fi
    fi

    log_info "Checking for Ruby updates..."
    if command -v rbenv >/dev/null 2>&1 && [[ "$DRY_RUN" == "false" ]]; then
        local current_version
        current_version=$(rbenv version-name 2>/dev/null || echo "none")
        log_info "Current Ruby version: $current_version"
        log_info "Run 'rbenv install -l' to see available versions"
        log_info "Run 'rbenv install <version> && rbenv global <version>' to upgrade"
    fi

    log_success "rbenv updated"
    echo
}

# ============================================================================
# CLI Tools Updates
# ============================================================================

update_cli_tools() {
    log_step "Updating CLI Tools"

    # Update GitHub CLI
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
                brew)
                    brew upgrade gh 2>/dev/null || log_info "gh is already up to date"
                    ;;
                *)
                    log_info "Manual update required for gh on $OS"
                    ;;
            esac
        fi
    fi

    # For macOS with Homebrew, all CLI tools are updated via brew upgrade
    if [[ "$OS" == "macos" ]]; then
        log_info "CLI tools updated via Homebrew (see system packages update above)"
    else
        # Update kubectl
        if command -v kubectl >/dev/null 2>&1; then
            log_info "Current kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
            log_info "To update kubectl, re-run: ./cli/install.sh"
        fi

        # Update doctl
        if command -v doctl >/dev/null 2>&1; then
            log_info "Current doctl version: $(doctl version)"
            log_info "To update doctl, re-run: ./cli/install.sh"
        fi

        # Update Helm
        if command -v helm >/dev/null 2>&1; then
            log_info "Current Helm version: $(helm version --short 2>/dev/null || helm version)"
            log_info "To update Helm, re-run: ./cli/install.sh"
        fi
    fi

    log_success "CLI tools checked"
    echo
}

# ============================================================================
# NPM Global Packages Update
# ============================================================================

update_npm_packages() {
    log_step "Updating NPM Global Packages"

    if ! command -v npm >/dev/null 2>&1; then
        log_info "npm not installed, skipping"
        echo
        return
    fi

    log_info "Updating global npm packages..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would run: npm update -g"
    else
        npm update -g 2>/dev/null || log_warning "Could not update npm global packages"
    fi

    log_success "NPM packages updated"
    echo
}

# ============================================================================
# Ruby Gems Update
# ============================================================================

update_ruby_gems() {
    log_step "Updating Ruby Gems"

    if ! command -v gem >/dev/null 2>&1; then
        log_info "gem not installed, skipping"
        echo
        return
    fi

    log_info "Updating RubyGems system..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would run: gem update --system"
        log_debug "[DRY-RUN] Would run: gem update"
    else
        gem update --system 2>/dev/null || log_warning "Could not update RubyGems system"

        log_info "Updating installed gems..."
        gem update 2>/dev/null || log_warning "Could not update gems"
    fi

    log_success "Ruby gems updated"
    echo
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log_step "Starting Updates"
    echo

    # Run all update functions
    update_system_packages
    update_macos_software
    update_firmware
    update_oh_my_zsh
    update_zsh_plugins
    update_pure_prompt
    update_nodenv
    update_rbenv
    update_cli_tools
    update_npm_packages
    update_ruby_gems

    log_step "Update Complete!"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry-run. Run without --dry-run to apply updates."
    else
        log_success "All updates completed successfully"
        log_info "You may need to restart your shell or run 'source ~/.zshrc' for some changes to take effect"
    fi
}

# Run main function
main
