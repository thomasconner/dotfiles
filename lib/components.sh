#!/usr/bin/env bash

# Component registry for ctdev

# Get the root directory of the dotfiles
if [[ -z "$DOTFILES_ROOT" ]]; then
    DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Define available components
# Format: name:description:install_script
declare -a COMPONENTS=(
    "apps:Desktop applications (Chrome, VSCode, Slack, etc.):components/apps/install.sh"
    "claude:Claude Code configuration and settings:components/claude/install.sh"
    "cli:CLI tools (jq, gh, kubectl, btop, etc.):components/cli/install.sh"
    "fonts:Nerd Fonts for terminal:components/fonts/install.sh"
    "git:Git configuration and aliases:components/git/install.sh"
    "macos:macOS system defaults (Dock, Finder, keyboard):components/macos/install.sh"
    "node:Node.js via nodenv:components/node/install.sh"
    "ruby:Ruby via rbenv:components/ruby/install.sh"
    "zsh:Zsh, Oh My Zsh, Pure prompt, plugins:components/zsh/install.sh"
)

# Default installation order (macos excluded - run explicitly with: ctdev install macos)
# Used by cmds/install.sh
# shellcheck disable=SC2034
DEFAULT_INSTALL_ORDER="apps claude cli fonts git node ruby zsh"

# List all available components
list_components() {
    local name desc script entry
    for entry in "${COMPONENTS[@]}"; do
        IFS=':' read -r name desc script <<< "$entry"
        echo "$name"
    done
}

# Get component description
get_component_description() {
    local target="$1"
    local name desc script entry
    for entry in "${COMPONENTS[@]}"; do
        IFS=':' read -r name desc script <<< "$entry"
        if [[ "$name" == "$target" ]]; then
            echo "$desc"
            return 0
        fi
    done
    return 1
}

# Get path to component install script
get_component_install_script() {
    local target="$1"
    local name desc script entry
    for entry in "${COMPONENTS[@]}"; do
        IFS=':' read -r name desc script <<< "$entry"
        if [[ "$name" == "$target" ]]; then
            echo "${DOTFILES_ROOT}/${script}"
            return 0
        fi
    done
    return 1
}

# Check if a component name is valid
is_valid_component() {
    local target="$1"
    local name desc script entry
    for entry in "${COMPONENTS[@]}"; do
        IFS=':' read -r name desc script <<< "$entry"
        if [[ "$name" == "$target" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if a component is installed
# First checks for installation marker, then falls back to heuristics
# Returns 0 if installed, 1 if not
is_component_installed() {
    local component="$1"

    # First check for installation marker (most reliable)
    if has_install_marker "$component"; then
        return 0
    fi

    # Fallback to heuristic checks (for backwards compatibility)
    case "$component" in
        apps)
            # Check if any app is installed (VSCode as indicator)
            command -v code >/dev/null 2>&1
            ;;
        claude)
            # Check if Claude config is symlinked
            [[ -L ~/.claude/CLAUDE.md ]] && [[ -e ~/.claude/CLAUDE.md ]]
            ;;
        cli)
            # Check for a few core CLI tools
            command -v jq >/dev/null 2>&1 && command -v gh >/dev/null 2>&1
            ;;
        fonts)
            # Check if Nerd Fonts are installed
            if [[ "$(uname -s)" == "Darwin" ]]; then
                ls ~/Library/Fonts/*Nerd* >/dev/null 2>&1
            else
                ls ~/.local/share/fonts/*Nerd* >/dev/null 2>&1 || ls /usr/share/fonts/*Nerd* >/dev/null 2>&1
            fi
            ;;
        git)
            # Check if git config is symlinked
            [[ -L ~/.gitconfig ]] && [[ -e ~/.gitconfig ]]
            ;;
        macos)
            # Check if key macOS defaults are set (Dock show-recents as indicator)
            [[ "$(uname -s)" == "Darwin" ]] && \
                [[ "$(defaults read com.apple.dock show-recents 2>/dev/null)" == "0" ]]
            ;;
        node)
            # Check if nodenv is installed
            [[ -d ~/.nodenv ]] && command -v node >/dev/null 2>&1
            ;;
        ruby)
            # Check if rbenv is installed
            [[ -d ~/.rbenv ]] && command -v ruby >/dev/null 2>&1
            ;;
        zsh)
            # Check if Oh My Zsh is installed
            [[ -d ~/.oh-my-zsh ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Get installation status string
get_component_status() {
    local component="$1"
    if is_component_installed "$component"; then
        echo "installed"
    else
        echo "not installed"
    fi
}

# Validate a list of components
# Returns 0 if all valid, 1 if any invalid
validate_components() {
    local invalid=()

    for comp in "$@"; do
        if ! is_valid_component "$comp"; then
            invalid+=("$comp")
        fi
    done

    if [[ ${#invalid[@]} -gt 0 ]]; then
        for inv in "${invalid[@]}"; do
            log_error "Unknown component: $inv"
        done
        echo ""
        echo "Available components:"
        list_components | while read -r name; do
            echo "  $name"
        done
        return 1
    fi

    return 0
}
