#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

# Show help for configure command
show_configure_help() {
    cat << 'EOF'
ctdev configure - Configure components

Usage: ctdev configure <TARGET> [OPTIONS]

Targets:
    git              Configure git user (name and email)
    macos            Configure macOS system defaults

Git Options:
    --name NAME      Set git user.name
    --email EMAIL    Set git user.email
    --local          Configure for current repo only (not global)

macOS Options:
    --reset          Reset to macOS system defaults

General Options:
    -h, --help       Show this help message
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev configure git                       Interactive git configuration (global)
    ctdev configure git --local               Configure git for current repo only
    ctdev configure git --name "Name" --email "email@example.com"
    ctdev configure git --local --name "Work Name" --email "work@example.com"
    ctdev configure macos                     Apply macOS preferences
    ctdev configure macos --reset             Reset to Apple defaults
EOF
}

# Main command handler
cmd_configure() {
    local target=""
    local args=()

    # Check for help first
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            show_configure_help
            return 0
        fi
    done

    # Get target (first non-flag argument)
    if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
        target="$1"
        shift
        args=("$@")
    fi

    if [[ -z "$target" ]]; then
        log_error "No target specified"
        echo ""
        echo "Usage: ctdev configure <TARGET>"
        echo ""
        echo "Targets:"
        echo "  git     Configure git user (name and email)"
        echo "  macos   Configure macOS system defaults"
        echo ""
        echo "Run 'ctdev configure --help' for more information."
        return 1
    fi

    case "$target" in
        git)
            configure_git "${args[@]}"
            ;;
        macos)
            configure_macos "${args[@]}"
            ;;
        *)
            log_error "Unknown target: $target"
            echo ""
            echo "Valid targets: git, macos"
            return 1
            ;;
    esac
}

# Configure git
configure_git() {
    local configure_script="$DOTFILES_ROOT/components/git/configure.sh"

    if [[ ! -f "$configure_script" ]]; then
        log_error "Git component not found. Run 'ctdev install git' first."
        return 1
    fi

    bash "$configure_script" "$@"
}

# Configure macOS
configure_macos() {
    local reset_mode=false

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --reset)
                reset_mode=true
                ;;
            -*)
                # Ignore other flags (handled by main dispatcher)
                ;;
            *)
                log_error "Unknown option: $arg"
                echo ""
                echo "Usage: ctdev configure macos [--reset] [--dry-run]"
                return 1
                ;;
        esac
    done

    # Only run on macOS
    if [[ "$(detect_os)" != "macos" ]]; then
        log_error "This command is only available on macOS"
        return 1
    fi

    if [[ "$reset_mode" == "true" ]]; then
        macos_reset
    else
        macos_apply
    fi
}

macos_apply() {
    log_step "Configuring macOS System Defaults"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure Dock settings (auto-hide, animations, recent apps)"
        log_info "[DRY-RUN] Would configure Finder settings (extensions, path bar, status bar)"
        log_info "[DRY-RUN] Would configure Keyboard settings (disable smart quotes/dashes)"
        log_info "[DRY-RUN] Would configure Dialog settings (expand save/print dialogs)"
        log_info "[DRY-RUN] Would configure Security settings (require password after sleep)"
        log_info "[DRY-RUN] Would restart Dock and Finder"
        log_success "macOS defaults would be configured"
        return 0
    fi

    # Dock Settings
    log_info "Configuring Dock..."
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.dock autohide-time-modifier -float 0
    defaults write com.apple.dock launchanim -bool false
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock minimize-to-application -bool true

    # Finder Settings
    log_info "Configuring Finder..."
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder QuitMenuItem -bool true

    # Keyboard Settings
    log_info "Configuring Keyboard..."
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Dialog Settings
    log_info "Configuring Dialogs..."
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Security Settings
    log_info "Configuring Security..."
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    # Apply changes
    log_info "Applying changes..."
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true

    log_success "macOS defaults configured"
    log_info "Some settings may require logout/restart to take full effect"
}

macos_reset() {
    log_step "Resetting macOS System Defaults"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would reset Dock, Finder, Keyboard, Dialog, Security settings"
        log_info "[DRY-RUN] Would restart Dock and Finder"
        log_success "macOS defaults would be reset"
        return 0
    fi

    log_info "Resetting Dock settings..."
    defaults delete com.apple.dock autohide-delay 2>/dev/null || true
    defaults delete com.apple.dock autohide-time-modifier 2>/dev/null || true
    defaults delete com.apple.dock launchanim 2>/dev/null || true
    defaults delete com.apple.dock show-recents 2>/dev/null || true
    defaults delete com.apple.dock minimize-to-application 2>/dev/null || true

    log_info "Resetting Finder settings..."
    defaults delete com.apple.finder AppleShowAllFiles 2>/dev/null || true
    defaults delete NSGlobalDomain AppleShowAllExtensions 2>/dev/null || true
    defaults delete com.apple.finder ShowPathbar 2>/dev/null || true
    defaults delete com.apple.finder ShowStatusBar 2>/dev/null || true
    defaults delete com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null || true
    defaults delete com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null || true
    defaults delete com.apple.finder FXDefaultSearchScope 2>/dev/null || true
    defaults delete com.apple.finder FXPreferredViewStyle 2>/dev/null || true
    defaults delete com.apple.finder QuitMenuItem 2>/dev/null || true

    log_info "Resetting Keyboard settings..."
    defaults delete NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticDashSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticSpellingCorrectionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticCapitalizationEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled 2>/dev/null || true
    defaults delete NSGlobalDomain KeyRepeat 2>/dev/null || true
    defaults delete NSGlobalDomain InitialKeyRepeat 2>/dev/null || true
    defaults delete NSGlobalDomain AppleKeyboardUIMode 2>/dev/null || true

    log_info "Resetting Dialog settings..."
    defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode 2>/dev/null || true
    defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 2>/dev/null || true
    defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint 2>/dev/null || true
    defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint2 2>/dev/null || true

    log_info "Resetting Security settings..."
    defaults delete com.apple.screensaver askForPassword 2>/dev/null || true
    defaults delete com.apple.screensaver askForPasswordDelay 2>/dev/null || true

    # Apply changes
    log_info "Applying changes..."
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true

    log_success "macOS defaults reset to system defaults"
    log_info "Some settings may require logout/restart to take full effect"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cmd_configure "$@"
fi
