#!/bin/bash

# Colorized output
# $1: string to print, must be quoted
# $2: optional, name of color, defaults to magenta
function message() {
    MAGENTA="\e[35m"
    DEFAULT="\e[0m"
    printf "$MAGENTA%s$DEFAULT\n" "$1"
}

message "Setting up Homebrew..."

declare -a brew_formulas=(
    # Upgrade default command line tools
    bash
    curl
    git
    wget
    zsh

    # Utilities
    colordiff
    emacs
    hub
    markdown
    mobile-shell
    nodenv    # Node environment manager
    ssh-copy-id
    z

    # Languages
    golang
    node
    python
    python3
)

declare -a cask_formulas=(
    firefox
    google-chrome
    iterm2
    kap    # Screen recorder
    lastpass
    qlmarkdown    # Markdown rendering in Finder quick look
    sketch
    spectacle    # Window manager
    spotify
    standard-notes
    visual-studio-code
)

declare -a cask_font_formulas=(
    font-blokk-neue
    font-fira-code
    font-lato
    font-noto-sans
    font-open-sans
    font-source-code-pro
)

declare -a cask_driver_formulas=(
    logitech-options
)

if [ ! -f "`which brew`" ]; then
    message "  Installing Homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

message "  Tapping caskroom/fonts..."
brew tap caskroom/fonts
message "  Tapping caskroom/drivers..."
brew tap caskroom/drivers

# Check if directory is writable, if not, take ownership of it
if [ ! -w /usr/local ]; then
    message "  Taking ownership of /usr/local..."
    sudo chown -R "$(whoami)" /usr/local
fi

message "  Updating Homebrew package lists..."
brew update &> /dev/null

message "  Upgrading installed packages..."
brew upgrade &> /dev/null

message "  Installing Brew formulas..."

# Install Brew formulas, suppress "already installed" warnings
for formula in "${brew_formulas[@]}"; do
    brew install "$formula" &> /dev/null
    message "    Installed $formula"
done

message "  Installing Brew Cask formulas..."

# Install Cask formulas, suppress "already installed" warnings
for formula in "${cask_formulas[@]}"; do
    brew cask install "$formula" &> /dev/null
    message "    Installed $formula"
done

message "  Installing Brew Cask font formulas..."

# Install Cask font formulas, suppress "already installed" warnings
for formula in "${cask_font_formulas[@]}"; do
    brew cask install "$formula" &> /dev/null
    message "    Installed $formula"
done

message "  Installing Brew driver formulas..."

# Install driver formulas, suppress "already installed" warnings
for formula in "${cask_driver_formulas[@]}"; do
    brew cask install "$formula" &> /dev/null
    message "    Installed $formula"
done

message "Homebrew done."

message "Run '/usr/local/Caskroom/lastpass/latest/LastPass Installer/LastPass Installer.app' to install the LastPass browser extension."
