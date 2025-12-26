#!/usr/bin/env bash

# Dependency management functions for ctdev CLI
# Part of the Conner Technology dotfiles

###############################################################################
# Common Tool Installation
###############################################################################

# Ensure git is installed
ensure_git_installed() {
  if ! command -v git >/dev/null 2>&1; then
    log_info "git is not installed. Installing..."
    install_package git
    log_success "git installed successfully"
  fi
}

# Ensure curl is installed
ensure_curl_installed() {
  if ! command -v curl >/dev/null 2>&1; then
    log_info "curl is not installed. Installing..."
    install_package curl
    log_success "curl installed successfully"
  fi
}

# Ensure wget is installed
ensure_wget_installed() {
  if ! command -v wget >/dev/null 2>&1; then
    log_info "wget is not installed. Installing..."
    install_package wget
    log_success "wget installed successfully"
  fi
}

# Ensure gpg is installed
ensure_gpg_installed() {
  if ! command -v gpg >/dev/null 2>&1; then
    log_info "gpg is not installed. Installing..."
    local os
    os=$(detect_os)
    # GPG package names vary by distro
    case "$os" in
      ubuntu|debian|linuxmint)
        install_package gpg
        ;;
      macos)
        install_package gnupg
        ;;
      *)
        install_package gpg
        ;;
    esac
    log_success "gpg installed successfully"
  fi
}

# Ensure unzip is installed
ensure_unzip_installed() {
  if ! command -v unzip >/dev/null 2>&1; then
    log_info "unzip is not installed. Installing..."
    install_package unzip
    log_success "unzip installed successfully"
  fi
}

###############################################################################
# macOS-Specific Package Management
###############################################################################

# Ensure Homebrew is installed (macOS)
ensure_brew_installed() {
  if command -v brew >/dev/null 2>&1; then
    log_debug "Homebrew is already installed"
    return 0
  fi

  if [[ "$(detect_os)" != "macos" ]]; then
    log_warning "Homebrew installation is only supported on macOS"
    return 1
  fi

  log_info "Homebrew is not installed. Installing..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Homebrew"
    return 0
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for the current session
  local brew_prefix
  brew_prefix=$(get_brew_prefix)
  if [[ -x "${brew_prefix}/bin/brew" ]]; then
    eval "$("${brew_prefix}/bin/brew" shellenv)"
  fi

  log_success "Homebrew installed successfully"
}

# Ensure Xcode Command Line Tools are installed (macOS)
ensure_xcode_cli_installed() {
  if [[ "$(detect_os)" != "macos" ]]; then
    log_debug "Xcode CLI tools are only needed on macOS"
    return 0
  fi

  # Check if xcode-select is available and tools are installed
  if xcode-select -p &>/dev/null; then
    log_debug "Xcode Command Line Tools are already installed"
    return 0
  fi

  log_info "Xcode Command Line Tools are not installed. Installing..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Xcode Command Line Tools"
    return 0
  fi

  # Trigger the installation prompt
  xcode-select --install 2>/dev/null || true

  # Wait for installation to complete (user interaction required)
  log_info "Please complete the Xcode Command Line Tools installation in the popup dialog..."
  log_info "Waiting for installation to complete..."

  # Poll until the tools are installed
  until xcode-select -p &>/dev/null; do
    sleep 5
  done

  log_success "Xcode Command Line Tools installed successfully"
}

# Install a Homebrew cask (macOS GUI applications)
install_brew_cask() {
  local cask="$1"

  if [[ "$(detect_os)" != "macos" ]]; then
    log_error "Homebrew casks are only supported on macOS"
    return 1
  fi

  ensure_brew_installed

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install cask: $cask"
    return 0
  fi

  if brew list --cask "$cask" &>/dev/null; then
    log_info "$cask is already installed"
    return 0
  fi

  log_info "Installing $cask..."
  brew install --cask "$cask"
  log_success "$cask installed successfully"
}
