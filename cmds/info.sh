#!/usr/bin/env bash

# ctdev info - Show system information

cmd_info() {
    local version
    version=$(get_version)

    echo
    log_step "System Information"
    echo

    # OS
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        # shellcheck disable=SC2153
        echo "  OS:              $NAME $VERSION"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  OS:              macOS $(sw_vers -productVersion)"
    else
        echo "  OS:              $(uname -s)"
    fi

    # Architecture
    echo "  Architecture:    $(uname -m)"

    # Package manager
    local pkg_manager
    pkg_manager=$(get_package_manager)
    echo "  Package Manager: $pkg_manager"

    # Shell
    echo "  Shell:           ${SHELL:-unknown}"

    # Dotfiles location
    echo "  Dotfiles:        $DOTFILES_ROOT"

    # ctdev version
    echo "  ctdev:           $version"

    echo
    log_step "Hardware"
    echo

    # CPU
    local cpu_info
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cpu_info=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
    elif [[ -f /proc/cpuinfo ]]; then
        cpu_info=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
    else
        cpu_info="unknown"
    fi
    echo "  CPU:             $cpu_info"

    # CPU cores
    local cpu_cores
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
    elif [[ -f /proc/cpuinfo ]]; then
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
    else
        cpu_cores=$(nproc 2>/dev/null || echo "unknown")
    fi
    echo "  CPU Cores:       $cpu_cores"

    # Memory
    local mem_total
    if [[ "$OSTYPE" == "darwin"* ]]; then
        mem_bytes=$(sysctl -n hw.memsize 2>/dev/null)
        if [[ -n "$mem_bytes" ]]; then
            mem_total="$((mem_bytes / 1024 / 1024 / 1024)) GB"
        else
            mem_total="unknown"
        fi
    elif [[ -f /proc/meminfo ]]; then
        mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_total="$((mem_kb / 1024 / 1024)) GB"
    else
        mem_total="unknown"
    fi
    echo "  Memory:          $mem_total"

    # GPU (if available)
    local gpu_info=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | sed 's/^ //')
    elif command -v lspci >/dev/null 2>&1; then
        gpu_info=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | sed 's/.*: //')
    elif command -v nvidia-smi >/dev/null 2>&1; then
        gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    fi
    if [[ -n "$gpu_info" ]]; then
        echo "  GPU:             $gpu_info"
    fi

    # Disk (root filesystem)
    local disk_info
    if command -v df >/dev/null 2>&1; then
        disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $2 " total, " $4 " available"}')
        echo "  Disk (/):        $disk_info"
    fi

    echo
}
