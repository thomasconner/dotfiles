#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing Ruby"

OS=$(detect_os)
PM=$(get_package_manager)
RUBY_VERSION=3.4.1
RUBY_GEMS=(colorls)

# Install rbenv if not present
if ! command -v rbenv >/dev/null 2>&1; then
  if [[ "$OS" == "macos" ]]; then
    log_info "Installing rbenv via Homebrew..."
    ensure_brew_installed
    brew install rbenv ruby-build
  else
    log_info "Installing rbenv via git..."
    ensure_git_repo "https://github.com/rbenv/rbenv.git" "${HOME}/.rbenv"
    ensure_git_repo "https://github.com/rbenv/ruby-build.git" "${HOME}/.rbenv/plugins/ruby-build"

    # Add to PATH for this session
    export PATH="${HOME}/.rbenv/bin:$PATH"
  fi
fi

# Initialize rbenv
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - bash)"
fi

if command -v rbenv >/dev/null 2>&1; then
  # Update rbenv (git installs only)
  if [[ -d "${HOME}/.rbenv/.git" ]]; then
    log_info "Updating rbenv and ruby-build plugins..."
    run_cmd git -C "${HOME}/.rbenv" pull --ff-only
    if [[ -d "${HOME}/.rbenv/plugins/ruby-build/.git" ]]; then
      run_cmd git -C "${HOME}/.rbenv/plugins/ruby-build" pull --ff-only
    fi
  fi

  # Install build dependencies
  if [[ "$OS" == "macos" ]]; then
    log_info "Installing Ruby build dependencies..."
    ensure_brew_installed
    for pkg in openssl readline libyaml gmp; do
      if ! brew list "$pkg" &>/dev/null; then
        run_cmd brew install "$pkg"
      fi
    done
  elif [[ "$PM" == "apt" ]]; then
    log_info "Installing Ruby build dependencies..."
    run_cmd maybe_sudo apt update
    run_cmd maybe_sudo apt install -y build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc
  elif [[ "$PM" == "dnf" ]]; then
    log_info "Installing Ruby build dependencies..."
    run_cmd maybe_sudo dnf groupinstall -y "Development Tools"
    run_cmd maybe_sudo dnf install -y openssl-devel libyaml-devel zlib-devel libffi-devel gmp-devel rust
  elif [[ "$PM" == "pacman" ]]; then
    log_info "Installing Ruby build dependencies..."
    run_cmd maybe_sudo pacman -S --noconfirm base-devel openssl libyaml zlib libffi gmp rust
  fi

  log_info "Ensuring Ruby ${RUBY_VERSION} with rbenv"

  # Install if missing
  if ! rbenv versions --bare | grep -qx "${RUBY_VERSION}"; then
    log_info "Installing Ruby ${RUBY_VERSION}..."
    run_cmd rbenv install "${RUBY_VERSION}"
  else
    log_success "Ruby ${RUBY_VERSION} already installed"
  fi

  # Set as global if not already
  CURRENT_GLOBAL="$(rbenv global 2>/dev/null || echo "none")"
  if [ "${CURRENT_GLOBAL}" != "${RUBY_VERSION}" ]; then
    log_info "Setting Ruby ${RUBY_VERSION} as global version"
    run_cmd rbenv global "${RUBY_VERSION}"
  else
    log_success "Ruby ${RUBY_VERSION} is already the global version"
  fi

  run_cmd rbenv rehash
  log_info "Using Ruby: $(ruby -v)"
else
  log_error "rbenv installation failed"
  exit 1
fi

# Install gems
log_info "Installing Ruby gems..."
for gem_name in "${RUBY_GEMS[@]}"; do
  if gem list -i "${gem_name}" > /dev/null 2>&1; then
    log_info "Updating ${gem_name}..."
    run_cmd gem update "${gem_name}"
  else
    log_info "Installing ${gem_name}..."
    run_cmd gem install "${gem_name}"
  fi
done

log_success "Ruby installation complete"
