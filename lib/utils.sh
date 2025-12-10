#!/usr/bin/env bash

# Shared utility functions for ctdev CLI
# Part of the Conner Technology dotfiles

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
        log_debug "[DRY-RUN] Would run: $*"
        return 0
    else
        "$@"
    fi
}

###############################################################################
# Logging Functions
###############################################################################

# Color codes for terminal output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Check if output supports colors
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
  USE_COLOR=true
else
  USE_COLOR=false
fi

# Log info message
log_info() {
  if [[ "$USE_COLOR" == "true" ]]; then
    echo -e "${BLUE}[INFO]${NC} $*"
  else
    echo "[INFO] $*"
  fi
}

# Log success message
log_success() {
  if [[ "$USE_COLOR" == "true" ]]; then
    echo -e "${GREEN}[✓]${NC} $*"
  else
    echo "[✓] $*"
  fi
}

# Log warning message to stderr
log_warning() {
  if [[ "$USE_COLOR" == "true" ]]; then
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
  else
    echo "[WARNING] $*" >&2
  fi
}

# Log error message to stderr
log_error() {
  if [[ "$USE_COLOR" == "true" ]]; then
    echo -e "${RED}[ERROR]${NC} $*" >&2
  else
    echo "[ERROR] $*" >&2
  fi
}

# Log step/section header
log_step() {
  if [[ "$USE_COLOR" == "true" ]]; then
    echo -e "${CYAN}==>${NC} $*"
  else
    echo "==> $*"
  fi
}

# Log debug message (only if VERBOSE is set)
log_debug() {
  if [[ "${VERBOSE:-false}" == "true" ]]; then
    if [[ "$USE_COLOR" == "true" ]]; then
      echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    else
      echo "[DEBUG] $*" >&2
    fi
  fi
}

###############################################################################
# Progress Indicators
###############################################################################

# Show a spinner while a process is running
# Usage: long_running_command & spinner $!
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'

  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Show progress for a task with a message
# Usage: with_spinner "Downloading files" long_running_command args
with_spinner() {
  local message="$1"
  shift

  printf "%s ... " "$message"

  # Run command in background
  "$@" > /dev/null 2>&1 &
  local pid=$!

  # Show spinner while waiting
  spinner $pid

  # Wait for command to complete and get exit code
  wait $pid
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    log_success "$message"
  else
    log_error "$message failed"
    return $exit_code
  fi
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
    local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$backup"
    log_info "Backed up $file to $backup"
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
    log_info "[DRY RUN] Would create symlink: $dest -> $src"
  else
    ln -sf "$src" "$dest"
    log_debug "Created symlink: $dest -> $src"
  fi
}

###############################################################################
# Platform Detection and Abstraction
###############################################################################

# Detect operating system
detect_os() {
  case "$(uname -s)" in
    Linux*)
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$ID"  # ubuntu, debian, arch, fedora, etc.
      else
        echo "linux"
      fi
      ;;
    Darwin*)
      echo "macos"
      ;;
    FreeBSD*)
      echo "freebsd"
      ;;
    CYGWIN*|MINGW*|MSYS*)
      echo "windows"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Detect CPU architecture
# Returns: amd64, arm64
detect_arch() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64)
      echo "amd64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    *)
      echo "$arch"
      ;;
  esac
}

# Get Homebrew prefix (differs between Intel and Apple Silicon Macs)
get_brew_prefix() {
  if [[ "$(detect_os)" == "macos" ]]; then
    if [[ "$(detect_arch)" == "arm64" ]]; then
      echo "/opt/homebrew"
    else
      echo "/usr/local"
    fi
  else
    echo "/home/linuxbrew/.linuxbrew"
  fi
}

# Check if running on macOS
is_macos() {
  [[ "$(detect_os)" == "macos" ]]
}

# Check if running on Linux
is_linux() {
  local os
  os=$(detect_os)
  [[ "$os" != "macos" && "$os" != "freebsd" && "$os" != "windows" && "$os" != "unknown" ]]
}

# Get the package manager for the current OS
get_package_manager() {
  local os
  os=$(detect_os)

  case "$os" in
    ubuntu|debian|linuxmint)
      echo "apt"
      ;;
    fedora|rhel|centos)
      echo "dnf"
      ;;
    arch|manjaro)
      echo "pacman"
      ;;
    macos)
      echo "brew"
      ;;
    freebsd)
      echo "pkg"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Helper to run command with sudo if not root
maybe_sudo() {
  if [ "$EUID" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# Install a package using the appropriate package manager
install_package() {
  local package="$1"
  local os
  local pm

  os=$(detect_os)
  pm=$(get_package_manager)

  log_debug "Installing $package on $os using $pm"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY RUN] Would install package: $package"
    return 0
  fi

  case "$pm" in
    apt)
      maybe_sudo apt update
      maybe_sudo apt install -y "$package"
      ;;
    dnf)
      maybe_sudo dnf install -y "$package"
      ;;
    pacman)
      maybe_sudo pacman -S --noconfirm "$package"
      ;;
    brew)
      brew install "$package"
      ;;
    pkg)
      maybe_sudo pkg install -y "$package"
      ;;
    *)
      log_error "Unsupported package manager or OS: $pm ($os)"
      log_error "Please install $package manually"
      return 1
      ;;
  esac
}

###############################################################################
# Dependency Management Functions
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
    log_info "[DRY RUN] Would install Homebrew"
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
    log_info "[DRY RUN] Would install Xcode Command Line Tools"
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
    log_info "[DRY RUN] Would install cask: $cask"
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

# Check if a directory exists and is a git repository, then pull or clone
ensure_git_repo() {
  local repo_url="$1"
  local target_dir="$2"
  local repo_name="${repo_url##*/}"
  repo_name="${repo_name%.git}"

  if [ -z "$repo_url" ] || [ -z "$target_dir" ]; then
    echo "Usage: ensure_git_repo <repo_url> <target_dir>"
    return 1
  fi

  ensure_git_installed

  if [ -d "$target_dir" ]; then
    if [ -d "$target_dir/.git" ]; then
      printf "%s is already installed, updating\n" "$repo_name"
      git -C "$target_dir" pull --ff-only
    else
      echo "Directory $target_dir exists but is not a git repository"
      return 1
    fi
  else
    printf "Cloning %s to %s\n" "$repo_name" "$target_dir"
    git clone "$repo_url" "$target_dir"
  fi
}
