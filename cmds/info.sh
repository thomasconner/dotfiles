#!/usr/bin/env bash

# ctdev info - Show system information

# ============================================================================
# Helper functions
# ============================================================================

check_tool() {
    local tool=$1
    local version_flag=${2:---version}

    if command -v "$tool" >/dev/null 2>&1; then
        local version
        set +e
        version=$($tool $version_flag 2>&1 | head -n 1)
        local exit_code=$?
        set -e

        if [[ $exit_code -eq 0 ]]; then
            log_check_pass "$tool" "$version"
        else
            log_check_pass "$tool" "installed (version check failed)"
        fi
    else
        log_check_fail "$tool"
    fi
}

human_size() {
    local bytes=$1
    # Use decimal units (SI) to match macOS Finder and diskutil display
    awk -v bytes="$bytes" 'BEGIN {
        if (bytes >= 1000000000000) printf "%.1f TB", bytes/1000000000000
        else if (bytes >= 1000000000) printf "%.1f GB", bytes/1000000000
        else if (bytes >= 1000000) printf "%.1f MB", bytes/1000000
        else if (bytes >= 1000) printf "%.1f KB", bytes/1000
        else printf "%d bytes", bytes
    }'
}

# ============================================================================
# Report sections
# ============================================================================

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

    echo "  Kernel: $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo "  Hostname: $(hostname)"

    # Uptime
    if command -v uptime >/dev/null 2>&1; then
        echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
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
        local mem_total mem_available mem_used
        mem_total=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
        mem_available=$(grep "^MemAvailable:" /proc/meminfo | awk '{print $2}')
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
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with APFS - get container-level usage for accurate numbers
        local container_info
        container_info=$(diskutil apfs list 2>/dev/null | grep -A 5 "Container disk" | head -6)
        if [[ -n "$container_info" ]]; then
            local total_bytes used_bytes pct_used
            total_bytes=$(echo "$container_info" | grep "Size (Capacity Ceiling)" | awk -F: '{print $2}' | awk '{print $1}')
            used_bytes=$(echo "$container_info" | grep "Capacity In Use" | awk -F: '{print $2}' | awk '{print $1}')
            pct_used=$(echo "$container_info" | grep "Capacity In Use" | grep -oE '[0-9.]+% used' | cut -d'%' -f1)

            if [[ -n "$total_bytes" && -n "$used_bytes" && -n "$pct_used" ]]; then
                echo "    Root (/): $(human_size "$used_bytes") used / $(human_size "$total_bytes") total (${pct_used}% full)"
            else
                # Fallback to df if parsing fails
                df -h / | tail -n 1 | awk '{print "    Root (/): " $3 " used / " $2 " total (" $5 " full)"}'
            fi
        else
            df -h / | tail -n 1 | awk '{print "    Root (/): " $3 " used / " $2 " total (" $5 " full)"}'
        fi
    elif command -v df >/dev/null 2>&1; then
        df -h / | tail -n 1 | awk '{print "    Root (/): " $3 " used / " $2 " total (" $5 " full)"}'
    fi

    echo
}

show_installed_tools() {
    log_step "Installed Tools"

    echo "Package Managers & Version Managers:"
    check_tool "nodenv" "version"
    check_tool "rbenv" "version"

    echo
    echo "Programming Languages:"
    check_tool "node" "--version"
    check_tool "npm" "--version"
    check_tool "ruby" "--version"
    check_tool "go" "version"
    check_tool "python3" "--version"

    echo
    echo "Shell & Terminal:"
    check_tool "zsh" "--version"
    check_tool "tmux" "-V"
    check_tool "btop" "--version"

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
    check_tool "age" "--version"
    check_tool "sops" "--version"
    check_tool "terraform" "--version"

    echo
    echo "Editors:"
    check_tool "code" "--version"
    check_tool "cursor" "--version"

    echo
}

show_environment_details() {
    log_step "Environment Details"

    echo "  Current Shell: ${SHELL:-unknown}"

    local pkg_manager
    pkg_manager=$(get_package_manager)
    echo "  Package Manager: ${pkg_manager}"

    local os_type
    os_type=$(detect_os)
    echo "  Detected OS Type: ${os_type}"

    echo "  User: ${USER:-unknown}"
    echo "  Home Directory: ${HOME:-unknown}"
    echo "  Terminal: ${TERM:-unknown}"
    echo "  Editor: ${EDITOR:-not set}"

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

    echo
}

# ============================================================================
# Main command
# ============================================================================

cmd_info() {
    local version
    version=$(get_version)

    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "   SYSTEM REPORT"
    echo "   Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "   ctdev version: ${version}"
    echo "═══════════════════════════════════════════════════════════════"
    echo

    show_system_info
    show_hardware_info
    show_installed_tools
    show_environment_details

    echo "═══════════════════════════════════════════════════════════════"
    echo "   Report complete!"
    echo "═══════════════════════════════════════════════════════════════"
    echo
}
