#!/usr/bin/env bash
set -euo pipefail

# Git configuration script - used by both install.sh and ctdev configure git
# Usage: configure.sh [OPTIONS]
#   --name NAME       Set git user.name
#   --email EMAIL     Set git user.email
#   --skip            Skip if already configured (for install)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

# Default values
GIT_USER_NAME=""
GIT_USER_EMAIL=""
SKIP_IF_CONFIGURED=false

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
        --skip)
            SKIP_IF_CONFIGURED=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Validate email format
validate_email() {
    local email="$1"
    [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

# Get current git user configuration
get_current_git_user() {
    local name email
    name=$(git config --global user.name 2>/dev/null || echo "")
    email=$(git config --global user.email 2>/dev/null || echo "")
    echo "$name|$email"
}

# Configure git user in ~/.gitconfig
configure_git_user() {
    local name="$1"
    local email="$2"

    if [[ -z "$name" ]]; then
        log_error "Git user name cannot be empty"
        return 1
    fi

    if [[ -z "$email" ]]; then
        log_error "Git user email cannot be empty"
        return 1
    fi

    if ! validate_email "$email"; then
        log_warning "Email format may be invalid: $email"
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure git user: $name <$email>"
        return 0
    fi

    git config --global user.name "$name"
    git config --global user.email "$email"

    log_success "Git user configured: $name <$email>"
}

# Prompt for git user info interactively
prompt_git_user() {
    local current_name current_email
    IFS='|' read -r current_name current_email <<< "$(get_current_git_user)"

    echo ""
    log_info "Git user configuration"
    echo ""

    # Prompt for name
    if [[ -n "$current_name" ]]; then
        read -r -p "Enter your name [$current_name]: " input_name
        GIT_USER_NAME="${input_name:-$current_name}"
    else
        read -r -p "Enter your name: " GIT_USER_NAME
    fi

    # Prompt for email
    if [[ -n "$current_email" ]]; then
        read -r -p "Enter your email [$current_email]: " input_email
        GIT_USER_EMAIL="${input_email:-$current_email}"
    else
        read -r -p "Enter your email: " GIT_USER_EMAIL
    fi
}

# Main logic
IFS='|' read -r current_name current_email <<< "$(get_current_git_user)"

# Skip if already configured and --skip was passed
if [[ "$SKIP_IF_CONFIGURED" == "true" && -n "$current_name" && -n "$current_email" ]]; then
    log_info "Git user already configured: $current_name <$current_email>"
    exit 0
fi

# If name and email provided via args, use them
if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    configure_git_user "$GIT_USER_NAME" "$GIT_USER_EMAIL"
elif [[ -t 0 ]]; then
    # Interactive terminal - prompt for input
    prompt_git_user
    if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
        configure_git_user "$GIT_USER_NAME" "$GIT_USER_EMAIL"
    else
        log_error "Name and email are required"
        exit 1
    fi
else
    # Non-interactive - error out
    log_error "Git user configuration requires --name and --email in non-interactive mode"
    exit 1
fi
