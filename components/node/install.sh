#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing Node.js"

# Check for dry-run mode
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install/configure:"
    log_info "  - nodenv version manager"
    log_info "  - node-build plugin"
    log_info "  - Node.js 24.0.0"
    log_info "  - Global npm packages: ngrok"
    log_success "Node.js dry-run complete"
    exit 0
fi

OS=$(detect_os)
NODE_VERSION=24.0.0
NODE_PACKAGES=(ngrok)

# Install nodenv if not present
if ! command -v nodenv >/dev/null 2>&1; then
  if [[ "$OS" == "macos" ]]; then
    log_info "Installing nodenv via Homebrew..."
    ensure_brew_installed
    brew install nodenv node-build
  else
    log_info "Installing nodenv via git..."
    ensure_git_repo "https://github.com/nodenv/nodenv.git" "${HOME}/.nodenv"
    ensure_git_repo "https://github.com/nodenv/node-build.git" "${HOME}/.nodenv/plugins/node-build"

    # Add to PATH for this session
    export PATH="${HOME}/.nodenv/bin:$PATH"
  fi
fi

# Initialize nodenv
if command -v nodenv >/dev/null 2>&1; then
  eval "$(nodenv init - bash)"
fi

if command -v nodenv >/dev/null 2>&1; then
  # Update nodenv (git installs only)
  if [[ -d "${HOME}/.nodenv/.git" ]]; then
    log_info "Updating nodenv and node-build plugins..."
    run_cmd git -C "${HOME}/.nodenv" pull --ff-only
    if [[ -d "${HOME}/.nodenv/plugins/node-build/.git" ]]; then
      run_cmd git -C "${HOME}/.nodenv/plugins/node-build" pull --ff-only
    fi
  fi

  log_info "Ensuring Node.js ${NODE_VERSION} with nodenv"

  # Install if missing
  if ! nodenv versions --bare | grep -qx "${NODE_VERSION}"; then
    log_info "Installing Node.js ${NODE_VERSION}..."
    run_cmd nodenv install "${NODE_VERSION}"
  else
    log_success "Node.js ${NODE_VERSION} already installed"
  fi

  # Set as global if not already
  CURRENT_GLOBAL=$(nodenv global 2>/dev/null || echo "none")
  if [ "${CURRENT_GLOBAL}" != "${NODE_VERSION}" ]; then
    log_info "Setting Node.js ${NODE_VERSION} as global version"
    run_cmd nodenv global "${NODE_VERSION}"
  else
    log_success "Node.js ${NODE_VERSION} is already the global version"
  fi

  run_cmd nodenv rehash
  log_info "Using Node.js version: $(node -v)"
else
  log_error "nodenv installation failed"
  exit 1
fi

# Install global npm packages
log_info "Installing global npm packages..."
for pkg in "${NODE_PACKAGES[@]}"; do
  if npm list -g --depth=0 2>/dev/null | grep -q " ${pkg}@"; then
    log_info "Updating ${pkg}..."
    run_cmd npm update -g "${pkg}"
  else
    log_info "Installing ${pkg}..."
    run_cmd npm install -g "${pkg}"
  fi
done

run_cmd nodenv rehash

log_success "Node.js installation complete"
