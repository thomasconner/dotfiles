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
    install <component...>    Install specific components
    uninstall <component...>  Remove specific components
    update                    Refresh package metadata (does not upgrade)
    upgrade [-y]              Upgrade installed components
    list                      List components with status
    info                      Show system information
    configure <target>        Configure git or macos settings
    gpu <subcommand>          Manage GPU driver signing for Secure Boot

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
    -f, --force      Force re-run install scripts
    --version        Show version information

Examples:
    ctdev install zsh git      Install specific components
    ctdev list                 Show all components with status
    ctdev update               Refresh package sources
    ctdev upgrade              Upgrade installed components
    ctdev upgrade -y           Upgrade without prompting
    ctdev configure git        Configure git user
    ctdev configure macos      Configure macOS settings

For help on a specific command:
    ctdev COMMAND --help
EOF
}

# Show help for install command
show_install_help() {
    cat << 'EOF'
ctdev install - Install specific components

Usage: ctdev install <COMPONENT...>

Installs one or more components. At least one component must be specified.

Use 'ctdev list' to see available components.

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
    -f, --force      Re-run install scripts even if already installed

Examples:
    ctdev install zsh          Install zsh configuration
    ctdev install node ruby    Install multiple components
    ctdev install --dry-run jq Preview installation

To upgrade installed components, use 'ctdev upgrade'.
EOF
}

# Show help for uninstall command
show_uninstall_help() {
    cat << 'EOF'
ctdev uninstall - Remove specific components

Usage: ctdev uninstall <COMPONENT...>

Removes one or more installed components. At least one component must be specified.

Use 'ctdev list' to see installed components.

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev uninstall ruby       Remove Ruby/rbenv
    ctdev uninstall node ruby  Remove multiple components
    ctdev uninstall --dry-run jq Preview removal
EOF
}

# Show help for update command
show_update_help() {
    cat << 'EOF'
ctdev update - Refresh package metadata

Usage: ctdev update [OPTIONS]

Refreshes package sources without upgrading anything:
- brew update (macOS)
- apt update (Debian/Ubuntu)
- git fetch for nodenv, rbenv, oh-my-zsh

This is a fast operation that checks for available updates.

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev update               Refresh all package sources

To actually upgrade components, use 'ctdev upgrade'.
EOF
}

# Show help for upgrade command
show_upgrade_help() {
    cat << 'EOF'
ctdev upgrade - Upgrade installed components

Usage: ctdev upgrade [OPTIONS] [COMPONENT...]

Upgrades system packages and installed components to latest versions.
If no components specified, upgrades all installed components.

Options:
    -h, --help       Show this help message
    -y, --yes        Skip confirmation prompt
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev upgrade              Upgrade all (with confirmation)
    ctdev upgrade -y           Upgrade all without prompting
    ctdev upgrade node ruby    Upgrade specific components
    ctdev upgrade --dry-run    Preview what would be upgraded
EOF
}

# Show help for list command
show_list_help() {
    cat << 'EOF'
ctdev list - List available components with status

Usage: ctdev list [OPTIONS]

Shows all components with their installation status:
- Green: installed
- Yellow: installed (update available)
- Grey: not installed

Options:
    -h, --help       Show this help message
EOF
}

# Show help for info command
show_info_help() {
    cat << 'EOF'
ctdev info - Show system information

Usage: ctdev info [OPTIONS]

Displays system information:
- OS and version
- Architecture
- Package manager
- Shell
- Dotfiles location

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
EOF
}

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
    --show           Show current git configuration

macOS Options:
    --reset          Reset to macOS system defaults
    --show           Show current macOS configuration

General Options:
    -h, --help       Show this help message
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev configure git                       Interactive git configuration (global)
    ctdev configure git --show                Show current git configuration
    ctdev configure git --local               Configure git for current repo only
    ctdev configure git --name "Name" --email "email@example.com"
    ctdev configure macos                     Apply macOS preferences
    ctdev configure macos --show              Show current macOS configuration
    ctdev configure macos --reset             Reset to Apple defaults
EOF
}

# Show help for gpu command
show_gpu_help() {
    cat << 'EOF'
ctdev gpu - Manage GPU driver signing for Secure Boot

Usage: ctdev gpu <subcommand> [OPTIONS]

Subcommands:
    status    Check secure boot and driver signing status
    setup     Configure MOK signing for NVIDIA drivers
    sign      Sign current NVIDIA kernel modules
    info      Show GPU hardware information

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
    -f, --force      Force re-run setup even if already configured

Examples:
    ctdev gpu status           Check if driver signing is configured
    ctdev gpu setup            Set up MOK signing (interactive)
    ctdev gpu sign             Re-sign modules after kernel update
    ctdev gpu info             Show GPU hardware details
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
            -f|--force)
                echo "FORCE=true"
                echo "export FORCE"
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
                # Not a flag - pass it through and continue processing
                args+=("$1")
                shift
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

# Validate that a command exists
require_command() {
    local cmd="$1"
    local valid_commands="install uninstall update upgrade list info configure gpu"

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
