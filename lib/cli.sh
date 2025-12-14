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
    update [component...]     Update components (all if none specified)
    info                      Show system information
    doctor                    Diagnose installation health
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
    ctdev update --dry-run     Preview updates
    ctdev doctor               Check installation health
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
    ctdev install              Install everything (except macos)
    ctdev install zsh          Minimal setup (shell/prompt only)
    ctdev install zsh git cli  Install specific components
    ctdev install macos        Configure macOS system defaults
    ctdev install --dry-run    Preview what would be installed
EOF
}

# Show help for update command
show_update_help() {
    cat << 'EOF'
ctdev update - Update dotfiles components

Usage: ctdev update [OPTIONS] [COMPONENT...]

If no components are specified, all installed components will be updated.
System packages (brew/apt/etc.) are always updated first.

Updatable Components:
    cli        GitHub CLI extensions
    node       nodenv, node-build, npm global packages
    ruby       rbenv, ruby-build, gems
    zsh        Oh My Zsh, plugins, Pure prompt

Other components (apps, fonts, git, macos) are managed by system
packages or are one-time setup - no separate update needed.

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev update           Update system packages and all components
    ctdev update zsh node  Update specific components
    ctdev update --dry-run Preview what would be updated
EOF
}

# Show help for info command
show_info_help() {
    cat << 'EOF'
ctdev info - Show system information

Usage: ctdev info [OPTIONS]

Displays detailed information about your system including:
- OS and hardware information
- Installed tools and their versions
- Environment configuration

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
EOF
}

# Show help for doctor command
show_doctor_help() {
    cat << 'EOF'
ctdev doctor - Diagnose installation health

Usage: ctdev doctor [OPTIONS]

Checks your installation for common issues:
- Verifies symlinks are correct
- Checks tool versions
- Reports missing dependencies
- Suggests fixes for issues found

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

# Validate that a command exists
require_command() {
    local cmd="$1"
    local valid_commands="install update info doctor list uninstall setup"

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
