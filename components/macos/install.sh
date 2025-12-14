#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/utils.sh"

# Only run on macOS
if [[ "$(detect_os)" != "macos" ]]; then
    log_info "macOS defaults: Skipping (not macOS)"
    exit 0
fi

log_step "Configuring macOS System Defaults"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would configure Dock settings (auto-hide, animations, recent apps)"
    log_info "[DRY-RUN] Would configure Finder settings (extensions, path bar, status bar)"
    log_info "[DRY-RUN] Would configure Keyboard settings (disable smart quotes/dashes)"
    log_info "[DRY-RUN] Would configure Dialog settings (expand save/print dialogs)"
    log_info "[DRY-RUN] Would configure Security settings (require password after sleep)"
    log_info "[DRY-RUN] Would restart Dock and Finder"
    log_success "macOS defaults would be configured"
    exit 0
fi

# ============================================================================
# Dock Settings
# ============================================================================
log_info "Configuring Dock..."

# Speed optimizations
defaults write com.apple.dock autohide-delay -float 0          # Remove auto-hide delay
defaults write com.apple.dock autohide-time-modifier -float 0  # Remove auto-hide animation
defaults write com.apple.dock launchanim -bool false           # Disable app launch bounce

# Cleaner dock
defaults write com.apple.dock show-recents -bool false         # Hide recent apps section
defaults write com.apple.dock minimize-to-application -bool true  # Minimize to app icon

# ============================================================================
# Finder Settings
# ============================================================================
log_info "Configuring Finder..."

# Developer essentials
# defaults write com.apple.finder AppleShowAllFiles -bool true           # Show hidden files
defaults write NSGlobalDomain AppleShowAllExtensions -bool true        # Show file extensions
defaults write com.apple.finder ShowPathbar -bool true                 # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true               # Show status bar
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # No .DS_Store on network
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true      # No .DS_Store on USB

# Search & behavior
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"    # Search current folder
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"    # List view by default
defaults write com.apple.finder QuitMenuItem -bool true                # Allow quitting Finder

# ============================================================================
# Keyboard & Input Settings
# ============================================================================
log_info "Configuring Keyboard..."

# Coding essentials - disable text mangling
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false    # Disable smart quotes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false     # Disable smart dashes
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false   # Disable auto-correct
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false       # Disable auto-capitalize
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false   # Disable double-space period

# Speed settings
defaults write NSGlobalDomain KeyRepeat -int 2                    # Fast key repeat (lower = faster)
defaults write NSGlobalDomain InitialKeyRepeat -int 15            # Short delay until repeat

# Full keyboard access (tab through all controls)
# defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# ============================================================================
# Dialog Settings
# ============================================================================
log_info "Configuring Dialogs..."

# Expand save and print dialogs by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# ============================================================================
# Security Settings
# ============================================================================
log_info "Configuring Security..."

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# ============================================================================
# Apply Changes
# ============================================================================
log_info "Applying changes..."

# Restart affected applications
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

log_success "macOS defaults configured"
log_info "Note: Some settings may require a logout/restart to take full effect"
