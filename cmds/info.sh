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

    # Memory (round to nearest GB)
    local mem_display
    if [[ "$OSTYPE" == "darwin"* ]]; then
        mem_bytes=$(sysctl -n hw.memsize 2>/dev/null)
        if [[ -n "$mem_bytes" ]]; then
            # Round to nearest GB
            mem_gb=$(( (mem_bytes + 536870912) / 1073741824 ))
            mem_display="${mem_gb} GB"
        else
            mem_display="unknown"
        fi
    elif [[ -f /proc/meminfo ]]; then
        mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        # Round to nearest GB (1 GB = 1048576 KB, add half for rounding)
        mem_gb=$(( (mem_kb + 524288) / 1048576 ))
        mem_display="${mem_gb} GB"
    else
        mem_display="unknown"
    fi
    echo "  Memory:          $mem_display"

    # GPU (if available)
    local gpu_info=""
    local gpu_vram=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | sed 's/^ //')
    elif command -v nvidia-smi >/dev/null 2>&1; then
        # NVIDIA GPU with nvidia-smi available
        gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        gpu_vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1 | sed 's/ MiB//')
        if [[ -n "$gpu_vram" ]]; then
            # Convert MiB to GB (round)
            gpu_vram_gb=$(( (gpu_vram + 512) / 1024 ))
            gpu_info="$gpu_info (${gpu_vram_gb} GB VRAM)"
        fi
    elif command -v lspci >/dev/null 2>&1; then
        gpu_info=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | sed 's/.*: //')
    fi
    if [[ -n "$gpu_info" ]]; then
        echo "  GPU:             $gpu_info"
    fi

    # Disk (root filesystem) - show used/total and percentage
    if command -v df >/dev/null 2>&1; then
        local disk_used disk_total disk_percent
        read -r disk_total disk_used disk_percent <<< "$(df -h / 2>/dev/null | awk 'NR==2 {print $2, $3, $5}')"
        # Format: 1.8T -> 1.8 TB, 500G -> 500 GB
        disk_total=$(echo "$disk_total" | sed 's/T$/ TB/; s/G$/ GB/; s/M$/ MB/')
        disk_used=$(echo "$disk_used" | sed 's/T$/ TB/; s/G$/ GB/; s/M$/ MB/')
        echo "  Disk (/):        $disk_used / $disk_total ($disk_percent used)"
    fi

    echo
}
