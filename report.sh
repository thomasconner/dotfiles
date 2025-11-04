#!/usr/bin/env bash

# System Report Script
# Generates a comprehensive report of system info, hardware, installed tools, and environment

set -euo pipefail

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities
# shellcheck source=scripts/utils.sh
source "${SCRIPT_DIR}/scripts/utils.sh"

# Read version from VERSION file
VERSION_FILE="${SCRIPT_DIR}/VERSION"
if [[ -f "${VERSION_FILE}" ]]; then
    DOTFILES_VERSION=$(cat "${VERSION_FILE}")
else
    DOTFILES_VERSION="unknown"
fi

# Script metadata
SCRIPT_NAME="System Report"
SCRIPT_VERSION="${DOTFILES_VERSION}"

#######################################
# Display help message
#######################################
show_help() {
    cat << EOF
${SCRIPT_NAME} v${SCRIPT_VERSION}

Generates a comprehensive system report including system info, hardware details,
installed tool versions, and environment configuration.

Usage:
    $(basename "$0") [OPTIONS]

Options:
    -h, --help       Show this help message
    --version        Show version information
    -v, --verbose    Enable verbose output

Examples:
    $(basename "$0")              # Generate full system report
    $(basename "$0") --verbose    # Generate report with debug info

EOF
}

#######################################
# Display version information
#######################################
show_version() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
}

#######################################
# Parse command line arguments
#######################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -v|--verbose)
                export VERBOSE=true
                set -x
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

#######################################
# Check if command exists and get version
#######################################
check_tool() {
    local tool=$1
    local version_flag=${2:---version}

    if command -v "$tool" >/dev/null 2>&1; then
        local version
        # Disable errexit temporarily to handle version commands that might fail
        set +e
        version=$($tool $version_flag 2>&1 | head -n 1)
        local exit_code=$?
        set -e

        if [[ $exit_code -eq 0 ]]; then
            echo "  ✓ $tool: $version"
        else
            echo "  ✓ $tool: installed (version check failed)"
        fi
    else
        echo "  ✗ $tool: not installed"
    fi
}

#######################################
# Get human-readable size
#######################################
human_size() {
    local bytes=$1
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$bytes"
    else
        echo "${bytes} bytes"
    fi
}

#######################################
# System Information Section
#######################################
show_system_info() {
    log_step "System Information"

    # OS and Distribution
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "  OS: $NAME $VERSION"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  OS: macOS $(sw_vers -productVersion)"
    else
        echo "  OS: $(uname -s)"
    fi

    # Kernel
    echo "  Kernel: $(uname -r)"

    # Architecture
    echo "  Architecture: $(uname -m)"

    # Hostname
    echo "  Hostname: $(hostname)"

    # Uptime
    if command -v uptime >/dev/null 2>&1; then
        echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    fi

    # Load Average
    if [[ -f /proc/loadavg ]]; then
        read -r load1 load5 load15 _ < /proc/loadavg
        echo "  Load Average: ${load1} (1m), ${load5} (5m), ${load15} (15m)"
    fi

    # Container Detection
    if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        echo "  Environment: Docker container"
    elif [[ "${container:-}" == "podman" ]]; then
        echo "  Environment: Podman container"
    else
        echo "  Environment: Native system"
    fi

    echo
}

#######################################
# Hardware Information Section
#######################################
show_hardware_info() {
    log_step "Hardware Information"

    # CPU
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model
        cpu_model=$(grep -m 1 "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)
        local cpu_cores
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
        echo "  CPU: ${cpu_model}"
        echo "  CPU Cores: ${cpu_cores}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  CPU: $(sysctl -n machdep.cpu.brand_string)"
        echo "  CPU Cores: $(sysctl -n hw.ncpu)"
    fi

    # Memory
    if [[ -f /proc/meminfo ]]; then
        local mem_total mem_available mem_used mem_free
        mem_total=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
        mem_available=$(grep "^MemAvailable:" /proc/meminfo | awk '{print $2}')
        mem_free=$(grep "^MemFree:" /proc/meminfo | awk '{print $2}')
        mem_used=$((mem_total - mem_available))

        echo "  Memory Total: $(human_size $((mem_total * 1024)))"
        echo "  Memory Used: $(human_size $((mem_used * 1024)))"
        echo "  Memory Available: $(human_size $((mem_available * 1024)))"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        local mem_total
        mem_total=$(sysctl -n hw.memsize)
        echo "  Memory Total: $(human_size "$mem_total")"
    fi

    # Disk Space
    echo "  Disk Usage:"
    if command -v df >/dev/null 2>&1; then
        df -h / | tail -n 1 | awk '{print "    Root (/): " $3 " used / " $2 " total (" $5 " full)"}'

        # Show home directory if different from root
        if [[ -d "$HOME" ]]; then
            local home_fs
            home_fs=$(df -h "$HOME" | tail -n 1 | awk '{print $6}')
            if [[ "$home_fs" != "/" ]]; then
                df -h "$HOME" | tail -n 1 | awk '{print "    Home (" $6 "): " $3 " used / " $2 " total (" $5 " full)"}'
            fi
        fi
    fi

    echo
}

#######################################
# Installed Tools Section
#######################################
show_installed_tools() {
    log_step "Installed Tools (from dotfiles)"

    echo "Package Managers & Version Managers:"
    check_tool "nodenv" "version"
    check_tool "rbenv" "version"

    echo
    echo "Programming Languages:"
    check_tool "node" "--version"
    check_tool "npm" "--version"
    check_tool "ruby" "--version"
    check_tool "gem" "--version"
    check_tool "go" "version"
    check_tool "python3" "--version"

    echo
    echo "Shell & Terminal:"
    check_tool "zsh" "--version"
    check_tool "tmux" "-V"
    check_tool "bash" "--version"

    echo
    echo "Version Control & Development:"
    check_tool "git" "--version"
    check_tool "gh" "--version"

    echo
    echo "CLI Tools:"
    check_tool "jq" "--version"
    check_tool "kubectl" "version --client --short"
    check_tool "doctl" "version"
    check_tool "helm" "version --short"
    check_tool "docker" "--version"

    echo
    echo "Applications:"
    check_tool "code" "--version"
    check_tool "google-chrome" "--version"
    check_tool "slack" "--version"

    echo
    echo "Global Packages:"
    if command -v npm >/dev/null 2>&1; then
        echo "  npm global packages:"
        npm list -g --depth=0 2>/dev/null | grep -E '@anthropic-ai/claude-code|ngrok' | sed 's/^/    /' || echo "    (none from dotfiles)"
    fi

    if command -v gem >/dev/null 2>&1; then
        echo "  Ruby gems:"
        gem list | grep -E '^colorls' | sed 's/^/    /' || echo "    (none from dotfiles)"
    fi

    echo
}

#######################################
# Environment Details Section
#######################################
show_environment_details() {
    log_step "Environment Details"

    # Shell
    echo "  Current Shell: ${SHELL:-unknown}"
    echo "  Default Shell: $(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "unknown")"

    # Package Manager
    local pkg_manager
    pkg_manager=$(get_package_manager)
    echo "  Package Manager: ${pkg_manager}"

    # OS Detection
    local os_type
    os_type=$(detect_os)
    echo "  Detected OS Type: ${os_type}"

    # User Info
    echo "  User: ${USER:-unknown} (UID: ${UID:-unknown})"
    echo "  Home Directory: ${HOME:-unknown}"

    # Terminal
    echo "  Terminal: ${TERM:-unknown}"
    if [[ -n "${COLORTERM:-}" ]]; then
        echo "  Color Support: ${COLORTERM}"
    fi

    # Editor
    echo "  Editor: ${EDITOR:-not set}"

    # Important Paths
    echo "  Oh My Zsh: ${ZSH:-~/.oh-my-zsh}"
    if [[ -d "${HOME}/.nodenv" ]]; then
        echo "  nodenv: ${HOME}/.nodenv"
    fi
    if [[ -d "${HOME}/.rbenv" ]]; then
        echo "  rbenv: ${HOME}/.rbenv"
    fi

    # Git Config
    if command -v git >/dev/null 2>&1; then
        echo "  Git User: $(git config --global user.name 2>/dev/null || echo "not configured")"
        echo "  Git Email: $(git config --global user.email 2>/dev/null || echo "not configured")"
    fi

    # Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            echo "  Docker: running"
        else
            echo "  Docker: installed but not running"
        fi
    fi

    # SSH Keys
    if [[ -d "${HOME}/.ssh" ]]; then
        local key_count
        key_count=$(find "${HOME}/.ssh" -name "id_*" -not -name "*.pub" 2>/dev/null | wc -l)
        echo "  SSH Keys: ${key_count} found"
    fi

    echo
}

#######################################
# Main function
#######################################
main() {
    parse_args "$@"

    # Header
    echo
    log_success "════════════════════════════════════════════════════════════════"
    log_success "   SYSTEM REPORT"
    log_success "   Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    log_success "   Dotfiles Version: ${DOTFILES_VERSION}"
    log_success "════════════════════════════════════════════════════════════════"
    echo

    # Generate report sections
    show_system_info
    show_hardware_info
    show_installed_tools
    show_environment_details

    # Footer
    log_success "════════════════════════════════════════════════════════════════"
    log_success "   Report complete!"
    log_success "════════════════════════════════════════════════════════════════"
    echo
}

# Run main function
main "$@"
