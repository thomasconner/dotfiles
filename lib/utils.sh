#!/usr/bin/env bash

# Shared utility functions for ctdev CLI
# Part of the Conner Technology dotfiles
#
# This file loads all utility modules and provides core functions.

# Get the directory where this script is located
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Load Utility Modules
###############################################################################

# Order matters: logging first (no dependencies), then platform, then packages, then github
source "${_LIB_DIR}/logging.sh"
source "${_LIB_DIR}/platform.sh"
source "${_LIB_DIR}/packages.sh"
source "${_LIB_DIR}/github.sh"
source "${_LIB_DIR}/gpu.sh"

###############################################################################
# Core Functions
###############################################################################

# Get the root directory of the dotfiles
get_dotfiles_root() {
    local script_path="${BASH_SOURCE[0]}"
    cd "$(dirname "$script_path")/.." && pwd
}

# Get version from VERSION file
get_version() {
    local dotfiles_root
    dotfiles_root="$(get_dotfiles_root)"
    local version_file="${dotfiles_root}/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "dev"
    fi
}

# Run a command, respecting DRY_RUN flag
run_cmd() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: $*"
        return 0
    else
        "$@"
    fi
}

###############################################################################
# Installation Marker Functions
###############################################################################

# Directory for installation markers
CTDEV_MARKER_DIR="${HOME}/.config/ctdev"

# Create an installation marker for a component
# Usage: create_install_marker "component_name"
create_install_marker() {
  local component="$1"
  local marker_file="${CTDEV_MARKER_DIR}/${component}.installed"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would create marker: $marker_file"
    return 0
  fi

  mkdir -p "$CTDEV_MARKER_DIR"
  date -Iseconds > "$marker_file"
  log_debug "Created installation marker for $component"
}

# Check if an installation marker exists for a component
# Usage: has_install_marker "component_name"
# Returns: 0 if marker exists, 1 if not
has_install_marker() {
  local component="$1"
  local marker_file="${CTDEV_MARKER_DIR}/${component}.installed"
  [[ -f "$marker_file" ]]
}

# Remove an installation marker for a component
# Usage: remove_install_marker "component_name"
remove_install_marker() {
  local component="$1"
  local marker_file="${CTDEV_MARKER_DIR}/${component}.installed"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would remove marker: $marker_file"
    return 0
  fi

  if [[ -f "$marker_file" ]]; then
    rm -f "$marker_file"
    log_debug "Removed installation marker for $component"
  fi
}

# Get the installation date from a marker
# Usage: get_install_date "component_name"
get_install_date() {
  local component="$1"
  local marker_file="${CTDEV_MARKER_DIR}/${component}.installed"

  if [[ -f "$marker_file" ]]; then
    cat "$marker_file"
  fi
}

###############################################################################
# Already-Installed Check Functions
###############################################################################

# Check if a CLI tool is already installed (respects FORCE flag)
# Usage: check_installed_cmd "tool" ["version_cmd"]
# Returns 0 if already installed (caller should exit 0), 1 otherwise
check_installed_cmd() {
  local cmd="$1"
  local version_cmd="${2:-}"

  if [[ "${FORCE:-false}" != "true" ]] && command -v "$cmd" >/dev/null 2>&1; then
    if [[ -n "$version_cmd" ]]; then
      log_info "$cmd is already installed: $(eval "$version_cmd" 2>&1 | head -n1)"
    else
      log_info "$cmd is already installed"
    fi
    return 0
  fi
  return 1
}

# Check if a macOS .app is already installed (respects FORCE flag)
# Usage: check_installed_app "App Name"
# Returns 0 if already installed (caller should exit 0), 1 otherwise
check_installed_app() {
  local app_name="$1"

  if [[ "${FORCE:-false}" != "true" ]] && [[ -d "/Applications/${app_name}.app" ]]; then
    log_info "$app_name is already installed"
    return 0
  fi
  return 1
}

###############################################################################
# Cleanup and Trap Functions
###############################################################################

# Cleanup function for temporary directories
# Usage:
#   TEMP_DIR=$(mktemp -d)
#   register_cleanup_trap "$TEMP_DIR"
#   ... do work ...
#   # cleanup happens automatically on exit
cleanup_temp_dir() {
  local temp_dir="${1:-}"
  if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
    rm -rf "$temp_dir"
    log_debug "Cleaned up temporary directory: $temp_dir"
  fi
}

# Register a trap to clean up a temporary directory on exit
register_cleanup_trap() {
  local temp_dir="$1"
  # shellcheck disable=SC2064
  trap "cleanup_temp_dir '$temp_dir'" EXIT INT TERM
}

###############################################################################
# Backup and Safety Functions
###############################################################################

# Backup a file before modifying it
# Only backs up regular files (not symlinks)
backup_file() {
  local file="$1"

  if [ -z "$file" ]; then
    log_error "backup_file: No file specified"
    return 1
  fi

  # Only backup if it's a regular file (not a symlink)
  if [ -f "$file" ] && [ ! -L "$file" ]; then
    local backup
    backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_info "[DRY-RUN] Would backup $file to $backup"
    else
      cp "$file" "$backup"
      log_info "Backed up $file to $backup"
    fi
    return 0
  fi

  return 0
}

# Safe symlink creation with backup
safe_symlink() {
  local src="$1"
  local dest="$2"

  if [ -z "$src" ] || [ -z "$dest" ]; then
    log_error "safe_symlink: Source and destination required"
    return 1
  fi

  if [ ! -e "$src" ]; then
    log_error "safe_symlink: Source does not exist: $src"
    return 1
  fi

  # Backup existing file if it's not already a symlink
  backup_file "$dest"

  # Create symlink
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would create symlink: $dest -> $src"
  else
    ln -sf "$src" "$dest"
    log_debug "Created symlink: $dest -> $src"
  fi
}
