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

macOS Options:
    --reset          Reset to macOS system defaults

General Options:
    -h, --help       Show this help message
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev configure git                       Interactive git configuration
    ctdev configure git --name "Name" --email "email@example.com"
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
    local macos_script="$DOTFILES_ROOT/cmds/macos.sh"

    if [[ "$(detect_os)" != "macos" ]]; then
        log_error "macOS configuration is only available on macOS"
        return 1
    fi

    if [[ ! -f "$macos_script" ]]; then
        log_error "macOS configuration script not found"
        return 1
    fi

    # Source and run the macos command
    source "$macos_script"
    cmd_macos "$@"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cmd_configure "$@"
fi
