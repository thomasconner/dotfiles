#!/usr/bin/env bash

# CLI parsing utilities for ctdev

# Get the root directory of the dotfiles
get_dotfiles_root() {
    local script_path="${BASH_SOURCE[0]}"
    cd "$(dirname "$script_path")/.." && pwd
}

DOTFILES_ROOT="$(get_dotfiles_root)"

# Get version from VERSION file
get_version() {
    local version_file="${DOTFILES_ROOT}/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "dev"
    fi
}

# Show version
show_version() {
    echo "ctdev v$(get_version)"
}

# Show main help
show_main_help() {
    cat << 'EOF'
ctdev - Conner Technology Dev CLI

Usage: ctdev [OPTIONS] COMMAND [ARGS]

Commands:
    install [component...]    Install components (all if none specified)
    update [component...]     Update system and installed components
    info                      Show system info and check installation health
    list                      List available components
    uninstall <component...>  Remove specific components
    setup                     Make ctdev available globally

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
    --version        Show version information

Examples:
    ctdev install              Install all components
    ctdev install zsh git      Install specific components
    ctdev update               Update system and installed components
    ctdev update --skip-system Update components only
    ctdev info                 Show system info and health checks
    ctdev setup                Add ctdev to your PATH

For help on a specific command:
    ctdev COMMAND --help
EOF
}

# Show help for install command
show_install_help() {
    cat << 'EOF'
ctdev install - Install dotfiles components

Usage: ctdev install [OPTIONS] [COMPONENT...]

If no components are specified, all components will be installed.
- Components not installed will be installed
- Components already installed will be checked for updates
- If updates are available, you will be prompted to update or defer

Note: 'macos' is not included by default - run it explicitly.

Components:
    apps       Desktop applications (Chrome, VSCode, Slack, etc.)
    cli        CLI tools (jq, gh, kubectl, btop, etc.)
    fonts      Nerd Fonts for terminal
    git        Git configuration and aliases
    macos      macOS system defaults (Dock, Finder, keyboard)
    node       Node.js via nodenv
    ruby       Ruby via rbenv
    zsh        Zsh, Oh My Zsh, Pure prompt, plugins

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev install              Install all components
    ctdev install zsh git      Install specific components
    ctdev install --dry-run    Preview what would be installed

To update installed components, use 'ctdev update'.
EOF
}

# Show help for info command
show_info_help() {
    cat << 'EOF'
ctdev info - Show system information and check installation health

Usage: ctdev info [OPTIONS]

Displays detailed information about your system including:
- OS and hardware information
- Environment configuration
- Installation health checks for all components
- Symlink verification
- Missing dependencies

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
EOF
}

# Show help for list command
show_list_help() {
    cat << 'EOF'
ctdev list - List available components

Usage: ctdev list [OPTIONS]

Options:
    -h, --help       Show this help message
    --installed      Show only installed components
EOF
}

# Show help for uninstall command
show_uninstall_help() {
    cat << 'EOF'
ctdev uninstall - Remove dotfiles components

Usage: ctdev uninstall <COMPONENT...>

At least one component must be specified.

Components:
    apps       Desktop applications
    cli        CLI tools
    fonts      Nerd Fonts
    git        Git configuration
    macos      macOS system defaults (resets to Apple defaults)
    node       Node.js (nodenv)
    ruby       Ruby (rbenv)
    zsh        Zsh configuration

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev uninstall ruby       Remove Ruby/rbenv
    ctdev uninstall apps fonts Remove multiple components
EOF
}

# Parse global flags and set environment variables
# Returns the remaining arguments after flags are consumed
# Usage: eval "$(parse_global_flags "$@")"
parse_global_flags() {
    local args=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "SHOW_HELP=true"
                shift
                ;;
            -v|--verbose)
                echo "VERBOSE=true"
                echo "export VERBOSE"
                shift
                ;;
            -n|--dry-run)
                echo "DRY_RUN=true"
                echo "export DRY_RUN"
                shift
                ;;
            --version)
                echo "SHOW_VERSION=true"
                shift
                ;;
            -*)
                # Unknown flag - pass it through
                args+=("$1")
                shift
                ;;
            *)
                # Not a flag - this and everything after is passed through
                args+=("$@")
                break
                ;;
        esac
    done

    # Output remaining args as a properly escaped array
    # Use declare -a to handle empty arrays safely with set -u
    if [[ ${#args[@]} -gt 0 ]]; then
        printf 'declare -a REMAINING_ARGS=('
        printf '%q ' "${args[@]}"
        printf ')\n'
    else
        echo 'declare -a REMAINING_ARGS=()'
    fi
}

# Show help for setup command
show_setup_help() {
    cat << 'EOF'
ctdev setup - Make ctdev available globally

Usage: ctdev setup [OPTIONS]

Creates a symlink to ctdev in ~/.local/bin so you can run it from anywhere.
No sudo required. Works on macOS and Linux.

Options:
    -h, --help       Show this help message
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev setup              Install ctdev globally
    ctdev setup --dry-run    Preview installation

Note: If ~/.local/bin is not in your PATH, the command will show you
how to add it. Running 'ctdev install zsh' also configures PATH automatically.
EOF
}

# Show help for update command
show_update_help() {
    cat << 'EOF'
ctdev update - Update system and installed components

Usage: ctdev update [OPTIONS] [COMPONENT...]

Updates system packages and installed components:
- System packages are updated via apt/brew/dnf/pacman
- Components with update support (zsh, node, ruby, cli) are updated
- If no components specified, all installed components are updated

Components with update support:
    zsh        Oh My Zsh, plugins, Pure prompt
    node       nodenv, node-build, global npm packages
    ruby       rbenv, ruby-build, gems
    cli        GitHub CLI extensions

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
    --skip-system    Skip system package updates (apt/brew/etc.)

Examples:
    ctdev update              Update everything
    ctdev update zsh node     Update specific components only
    ctdev update --skip-system Update components without system packages
    ctdev update --dry-run    Preview what would be updated
EOF
}

# Validate that a command exists
require_command() {
    local cmd="$1"
    local valid_commands="install info list uninstall setup update"

    if [[ -z "$cmd" ]]; then
        return 1
    fi

    for valid in $valid_commands; do
        if [[ "$cmd" == "$valid" ]]; then
            return 0
        fi
    done

    return 1
}
