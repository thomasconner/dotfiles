#!/usr/bin/env bash

# Logging and progress indicator functions for ctdev CLI
# Part of the Conner Technology dotfiles

# Guard against multiple sourcing
[[ -n "${_CTDEV_LOGGING_LOADED:-}" ]] && return 0
_CTDEV_LOGGING_LOADED=1

###############################################################################
# Color Configuration
###############################################################################

# Color codes for terminal output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Check if output supports colors
# Respects NO_COLOR environment variable (https://no-color.org/)
if [[ -n "${NO_COLOR:-}" ]]; then
  USE_COLOR=false
elif [[ -n "${FORCE_COLOR:-}" ]]; then
  USE_COLOR=true
elif [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null) -ge 8 ]]; then
  USE_COLOR=true
else
  USE_COLOR=false
fi

###############################################################################
# Logging Functions
###############################################################################

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

# Log a passing check (green checkmark)
# Usage: log_check_pass "tool_name" "details"
log_check_pass() {
  local name="$1"
  local details="${2:-}"
  if [[ "$USE_COLOR" == "true" ]]; then
    if [[ -n "$details" ]]; then
      echo -e "  ${GREEN}[✓]${NC} ${name}: ${details}"
    else
      echo -e "  ${GREEN}[✓]${NC} ${name}"
    fi
  else
    if [[ -n "$details" ]]; then
      echo "  [✓] ${name}: ${details}"
    else
      echo "  [✓] ${name}"
    fi
  fi
}

# Log a failing check (yellow X)
# Usage: log_check_fail "tool_name" "details"
log_check_fail() {
  local name="$1"
  local details="${2:-not installed}"
  if [[ "$USE_COLOR" == "true" ]]; then
    echo -e "  ${YELLOW}[✗]${NC} ${name}: ${details}"
  else
    echo "  [✗] ${name}: ${details}"
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
  # shellcheck disable=SC1003
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
