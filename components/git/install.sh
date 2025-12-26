#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
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
      echo "  --name NAME       Set git user.name"
      echo "  --email EMAIL     Set git user.email"
      echo "  --skip-user-config  Skip user configuration (use defaults, warn if not set)"
      echo "  -h, --help        Show this help message"
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

# Symlink main git configuration files
safe_symlink "$SCRIPT_DIR/.gitconfig" "${HOME}/.gitconfig"
safe_symlink "$SCRIPT_DIR/.gitignore" "${HOME}/.gitignore"

# Validate email format (basic check)
validate_email() {
  local email="$1"
  if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    return 0
  fi
  return 1
}

# Validate name (non-empty, reasonable characters)
validate_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    return 1
  fi
  # Allow letters, numbers, spaces, hyphens, apostrophes, periods
  if [[ "$name" =~ ^[A-Za-z0-9\ \'\.\-]+$ ]]; then
    return 0
  fi
  return 1
}

# Handle .gitconfig.local (user-specific settings)
configure_git_user() {
  local name="$1"
  local email="$2"
  local config_file="${HOME}/.gitconfig.local"

  # Validate inputs
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

  # Use git config directly (safer than heredoc with user input)
  git config --file "$config_file" user.name "$name"
  git config --file "$config_file" user.email "$email"

  log_success "Git user configured: $name <$email>"
}

# Check current git user configuration
get_current_git_user() {
  local name email
  name=$(git config --global user.name 2>/dev/null || echo "")
  email=$(git config --global user.email 2>/dev/null || echo "")
  echo "$name|$email"
}

# Prompt for git user info interactively
prompt_git_user() {
  local current_name current_email
  IFS='|' read -r current_name current_email <<< "$(get_current_git_user)"

  echo ""
  log_info "Git user configuration required"
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

# Main logic for user configuration
if [[ ! -f "${HOME}/.gitconfig.local" ]]; then
  # No local config exists - need to create one

  if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    # Both provided via arguments
    configure_git_user "$GIT_USER_NAME" "$GIT_USER_EMAIL"
  elif [[ "$SKIP_USER_CONFIG" == "true" ]]; then
    # Skip was requested - copy template and warn
    run_cmd cp "$SCRIPT_DIR/.gitconfig.local.template" "${HOME}/.gitconfig.local"
    log_warning "Git user not configured. Please update ~/.gitconfig.local with your name and email"
    log_info "Or run: git config --global user.name 'Your Name'"
    log_info "        git config --global user.email 'your@email.com'"
  elif [[ -t 0 ]]; then
    # Interactive terminal - prompt for input
    prompt_git_user
    if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
      configure_git_user "$GIT_USER_NAME" "$GIT_USER_EMAIL"
    else
      run_cmd cp "$SCRIPT_DIR/.gitconfig.local.template" "${HOME}/.gitconfig.local"
      log_warning "Git user not configured. Please update ~/.gitconfig.local"
    fi
  else
    # Non-interactive - copy template and warn
    run_cmd cp "$SCRIPT_DIR/.gitconfig.local.template" "${HOME}/.gitconfig.local"
    log_warning "Git user not configured (non-interactive mode)"
    log_info "Run with --name and --email arguments, or update ~/.gitconfig.local manually"
  fi
else
  # Local config exists - check if user is properly configured
  IFS='|' read -r current_name current_email <<< "$(get_current_git_user)"

  if [[ -z "$current_name" || -z "$current_email" ]]; then
    log_warning "Git user name or email not configured in ~/.gitconfig.local"

    if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
      # Update with provided values
      configure_git_user "$GIT_USER_NAME" "$GIT_USER_EMAIL"
    elif [[ "$SKIP_USER_CONFIG" != "true" && -t 0 ]]; then
      # Interactive - ask if they want to configure now
      read -r -p "Would you like to configure git user now? [y/N]: " response
      if [[ "$response" =~ ^[Yy] ]]; then
        prompt_git_user
        if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
          configure_git_user "$GIT_USER_NAME" "$GIT_USER_EMAIL"
        fi
      else
        log_warning "Skipping git user configuration"
        log_info "Run: git config --global user.name 'Your Name'"
        log_info "     git config --global user.email 'your@email.com'"
      fi
    else
      log_warning "Please configure git user manually:"
      log_info "  git config --global user.name 'Your Name'"
      log_info "  git config --global user.email 'your@email.com'"
    fi
  else
    log_info "Git user already configured: $current_name <$current_email>"
  fi
fi

log_success "Git configuration complete"
