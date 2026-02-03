#!/usr/bin/env bash

# ctdev macos - Configure macOS system defaults

cmd_macos() {
    local reset_mode=false

    # Parse subcommand arguments
    for arg in "$@"; do
        case "$arg" in
            -h|--help|-v|--verbose|-n|--dry-run)
                # Already handled by main dispatcher
                ;;
            --reset)
                reset_mode=true
                ;;
            *)
                log_error "Unknown option: $arg"
                echo ""
                echo "Usage: ctdev macos [--reset] [--dry-run]"
                echo ""
                echo "Options:"
                echo "  --reset    Reset to macOS system defaults"
                echo "  --dry-run  Show what would be changed without making changes"
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
        macos_configure
    fi
}

macos_configure() {
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
