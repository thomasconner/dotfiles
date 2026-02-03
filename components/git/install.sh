#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

# Default values
GIT_USER_NAME=""
GIT_USER_EMAIL=""
SKIP_USER_CONFIG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            GIT_USER_NAME="$2"
            shift 2
            ;;
        --email)
            GIT_USER_EMAIL="$2"
            shift 2
            ;;
        --skip-user-config)
            SKIP_USER_CONFIG=true
            shift
            ;;
        -h|--help)
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --name NAME          Set git user.name"
            echo "  --email EMAIL        Set git user.email"
            echo "  --skip-user-config   Skip user configuration"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

log_step "Installing git configuration"

# Ensure git is installed
ensure_git_installed

# Symlink main git configuration file
safe_symlink "$SCRIPT_DIR/.gitconfig" "${HOME}/.gitconfig"

# Handle user configuration
if [[ "$SKIP_USER_CONFIG" == "true" ]]; then
    log_warning "Git user not configured. Run: ctdev configure git"
else
    # Run configure.sh with appropriate flags
    configure_args=()
    if [[ -n "$GIT_USER_NAME" ]]; then
        configure_args+=(--name "$GIT_USER_NAME")
    fi
    if [[ -n "$GIT_USER_EMAIL" ]]; then
        configure_args+=(--email "$GIT_USER_EMAIL")
    fi
    # Skip if already configured during install
    configure_args+=(--skip)

    bash "$SCRIPT_DIR/configure.sh" "${configure_args[@]}"
fi

log_success "Git configuration complete"
