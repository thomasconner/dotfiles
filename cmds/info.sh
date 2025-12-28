#!/usr/bin/env bash

# ctdev info - Show system information and diagnose installation health

# ============================================================================
# Helper functions
# ============================================================================

check_tool() {
    local tool=$1
    local version_flag=${2:---version}

    if command -v "$tool" >/dev/null 2>&1; then
        local version
        set +e
        # shellcheck disable=SC2086
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
    # Use binary units (1024) since RAM is measured in GiB, not decimal GB
    awk -v bytes="$bytes" 'BEGIN {
        if (bytes >= 1099511627776) printf "%.1f TB", bytes/1099511627776
        else if (bytes >= 1073741824) printf "%.1f GB", bytes/1073741824
        else if (bytes >= 1048576) printf "%.1f MB", bytes/1048576
        else if (bytes >= 1024) printf "%.1f KB", bytes/1024
        else printf "%d bytes", bytes
    }'
}

# ============================================================================
# Health check functions (from doctor)
# ============================================================================

check_symlink() {
    local name="$1"
    local target="$2"
    local expected_source="$3"

    if [[ -L "$target" ]]; then
        if [[ -e "$target" ]]; then
            local actual_real expected_real
            actual_real=$(realpath "$target" 2>/dev/null) || actual_real=""
            expected_real=$(realpath "$expected_source" 2>/dev/null) || expected_real=""

            if [[ -n "$actual_real" && "$actual_real" == "$expected_real" ]]; then
                log_check_pass "$name" "OK"
                return 0
            fi
        fi
        log_check_fail "$name" "symlink points to wrong location"
        echo "      Expected: $expected_source"
        echo "      Actual: $(readlink "$target")"
        return 1
    elif [[ -f "$target" ]]; then
        log_check_fail "$name" "file exists but is not a symlink"
        echo "      Fix: backup and re-run ctdev install"
        return 1
    else
        log_check_fail "$name" "not configured"
        return 1
    fi
}

check_command() {
    local name="$1"
    local cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        log_check_pass "$name" "installed"
        return 0
    else
        log_check_fail "$name" "not installed"
        return 1
    fi
}

check_directory() {
    local name="$1"
    local dir="$2"

    if [[ -d "$dir" ]]; then
        log_check_pass "$name" "OK"
        return 0
    else
        log_check_fail "$name" "directory missing"
        echo "      Expected: $dir"
        return 1
    fi
}

# ============================================================================
# System info sections
# ============================================================================

show_system_info() {
    log_step "System Information"

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        # shellcheck disable=SC2153
        echo "  OS: $NAME $VERSION"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  OS: macOS $(sw_vers -productVersion)"
    else
        echo "  OS: $(uname -s)"
    fi

    echo "  Kernel: $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo "  Hostname: $(hostname)"

    if command -v uptime >/dev/null 2>&1; then
        echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    fi

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
    echo "  CPU:"
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model
        cpu_model=$(grep -m 1 "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)
        local cpu_cores
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
        echo "    Model: ${cpu_model}"
        echo "    Cores: ${cpu_cores}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "    Model: $(sysctl -n machdep.cpu.brand_string)"
        echo "    Cores: $(sysctl -n hw.ncpu)"
    fi

    # Memory
    echo "  Memory:"
    if [[ -f /proc/meminfo ]]; then
        local mem_total mem_available mem_used
        mem_total=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
        mem_available=$(grep "^MemAvailable:" /proc/meminfo | awk '{print $2}')
        mem_used=$((mem_total - mem_available))

        echo "    Total: $(human_size $((mem_total * 1024)))"
        echo "    Used: $(human_size $((mem_used * 1024)))"
        echo "    Available: $(human_size $((mem_available * 1024)))"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        local mem_total page_size pages_free pages_active pages_inactive pages_wired
        mem_total=$(sysctl -n hw.memsize)
        page_size=$(sysctl -n hw.pagesize)

        # Parse vm_stat output
        pages_free=$(vm_stat | awk '/Pages free/ {gsub(/\./,"",$3); print $3}')
        pages_active=$(vm_stat | awk '/Pages active/ {gsub(/\./,"",$3); print $3}')
        pages_inactive=$(vm_stat | awk '/Pages inactive/ {gsub(/\./,"",$3); print $3}')
        pages_wired=$(vm_stat | awk '/Pages wired/ {gsub(/\./,"",$4); print $4}')

        local mem_used mem_available
        mem_used=$(( (pages_active + pages_wired) * page_size ))
        mem_available=$(( (pages_free + pages_inactive) * page_size ))

        echo "    Total: $(human_size "$mem_total")"
        echo "    Used: $(human_size "$mem_used")"
        echo "    Available: $(human_size "$mem_available")"
    fi

    # GPU
    echo "  GPU:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local gpu_info
        gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset Model:|VRAM|Metal" || true)
        if [[ -n "$gpu_info" ]]; then
            echo "$gpu_info" | while read -r line; do
                echo "    ${line}"
            done
        else
            echo "    No GPU information available"
        fi
    elif command -v nvidia-smi >/dev/null 2>&1; then
        # NVIDIA GPU with detailed info
        # Get CUDA version from nvidia-smi header
        local cuda_version
        cuda_version=$(nvidia-smi 2>/dev/null | grep "CUDA Version" | grep -oE "CUDA Version: [0-9.]+" | cut -d' ' -f3)

        local gpu_count=0
        nvidia-smi --query-gpu=name,memory.used,memory.total,power.draw,power.limit,temperature.gpu,driver_version --format=csv,noheader,nounits 2>/dev/null | while IFS=',' read -r name mem_used mem_total power_draw power_cap temp driver; do
            gpu_count=$((gpu_count + 1))
            # Trim whitespace
            name=$(echo "$name" | xargs)
            mem_used=$(echo "$mem_used" | xargs)
            mem_total=$(echo "$mem_total" | xargs)
            power_draw=$(echo "$power_draw" | xargs)
            power_cap=$(echo "$power_cap" | xargs)
            temp=$(echo "$temp" | xargs)
            driver=$(echo "$driver" | xargs)

            # Convert MiB to GB (divide by 1024)
            local mem_used_gb mem_total_gb
            mem_used_gb=$(awk "BEGIN {printf \"%.1f\", $mem_used / 1024}")
            mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total / 1024}")

            echo "    NVIDIA GPU ${gpu_count}:"
            echo "      Model: ${name}"
            echo "      Memory: ${mem_used_gb} GB used / ${mem_total_gb} GB total"
            echo "      Power: ${power_draw}W / ${power_cap}W"
            echo "      Temperature: ${temp}C"
            if [[ $gpu_count -eq 1 ]]; then
                echo "      Driver: ${driver}"
                [[ -n "$cuda_version" ]] && echo "      CUDA: ${cuda_version}"
            fi
        done

        # Also show any other GPUs (AMD/Intel) via lspci
        if command -v lspci >/dev/null 2>&1; then
            lspci 2>/dev/null | grep -iE "vga|3d|display" | grep -vi nvidia | while read -r line; do
                local gpu_name
                gpu_name="${line#*: }"
                echo "    Other: ${gpu_name}"
            done
        fi
    elif command -v lspci >/dev/null 2>&1; then
        # Fallback to lspci for basic GPU info
        lspci 2>/dev/null | grep -iE "vga|3d|display" | while read -r line; do
            local gpu_name
            gpu_name="${line#*: }"
            echo "    ${gpu_name}"
        done
    elif [[ -d /sys/class/drm ]]; then
        # Fallback: check DRM subsystem
        for card in /sys/class/drm/card[0-9]*; do
            if [[ -f "$card/device/vendor" ]]; then
                echo "    GPU detected (use lspci for details)"
                break
            fi
        done
    else
        echo "    No GPU detected or lspci not available"
    fi

    # Disks
    echo "  Disks:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: show only main disk and real external volumes
        # Filter out system volumes, simulator volumes, and disk images
        df -h 2>/dev/null | grep -E "^/dev/" | while read -r line; do
            local mount_point used total pct avail
            mount_point=$(echo "$line" | awk '{print $9}')
            used=$(echo "$line" | awk '{print $3}')
            total=$(echo "$line" | awk '{print $2}')
            avail=$(echo "$line" | awk '{print $4}')
            pct=$(echo "$line" | awk '{print $5}')

            # Skip system volumes and temporary mounts
            case "$mount_point" in
                /System/Volumes/*|/Library/Developer/*|/private/var/*)
                    continue
                    ;;
            esac

            # For root, show as "Macintosh HD" style
            if [[ "$mount_point" == "/" ]]; then
                echo "    Macintosh HD (/):"
            else
                echo "    ${mount_point}:"
            fi
            echo "      Total: ${total}"
            echo "      Used: ${used} (${pct})"
            echo "      Available: ${avail}"
        done
    else
        # Linux: show real disks, filter out virtual/system mounts
        df -h 2>/dev/null | grep -E "^/dev/" | while read -r line; do
            local mount_point used total pct avail filesystem
            filesystem=$(echo "$line" | awk '{print $1}')
            used=$(echo "$line" | awk '{print $3}')
            total=$(echo "$line" | awk '{print $2}')
            avail=$(echo "$line" | awk '{print $4}')
            pct=$(echo "$line" | awk '{print $5}')
            mount_point=$(echo "$line" | awk '{print $6}')

            # Skip loop devices, snap mounts, and system partitions
            case "$filesystem" in
                /dev/loop*) continue ;;
            esac
            case "$mount_point" in
                /snap/*|/boot*|/run/*|/dev/*|/var/lib/docker/*) continue ;;
            esac

            # Label root filesystem nicely
            if [[ "$mount_point" == "/" ]]; then
                echo "    /:"
            else
                echo "    ${mount_point}:"
            fi
            echo "      Device: ${filesystem}"
            echo "      Total: ${total}"
            echo "      Used: ${used} (${pct})"
            echo "      Available: ${avail}"
        done
    fi

    # Network Interfaces
    echo "  Network:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: get active interfaces with IP addresses
        # Use networksetup to get the primary interface info
        local active_ifaces
        active_ifaces=$(ifconfig 2>/dev/null | awk '
            /^[a-z]/ { iface=$1; gsub(/:$/,"",iface) }
            /inet / && !/127\.0\.0\.1/ { print iface, $2 }
        ')

        if [[ -n "$active_ifaces" ]]; then
            echo "$active_ifaces" | while read -r iface ip; do
                # Only show common interfaces (en0, en1, etc.)
                case "$iface" in
                    en[0-9]*|bridge[0-9]*|utun[0-9]*)
                        echo "    ${iface}: ${ip}"
                        ;;
                esac
            done
        else
            echo "    No active network interfaces"
        fi
    elif command -v ip >/dev/null 2>&1; then
        # Linux: use ip command for detailed info
        # Get list of interfaces (excluding loopback)
        local ifaces
        ifaces=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | awk '{print $1}' | grep -v "^lo$" || true)

        for iface in $ifaces; do
            local state mac ipaddr
            state=$(ip -o link show "$iface" 2>/dev/null | grep -oE "state [A-Z]+" | awk '{print $2}' || true)
            mac=$(ip -o link show "$iface" 2>/dev/null | grep -oE "link/ether [0-9a-f:]+" | awk '{print $2}' || true)
            ipaddr=$(ip -4 addr show "$iface" 2>/dev/null | grep -oE "inet [0-9.]+" | head -1 | awk '{print $2}' || true)

            # Only show interfaces with IP or that are UP
            if [[ -n "$ipaddr" ]] || [[ "$state" == "UP" ]]; then
                echo "    ${iface}:"
                [[ -n "$ipaddr" ]] && echo "      IP: ${ipaddr}"
                [[ -n "$mac" ]] && echo "      MAC: ${mac}"
                [[ -n "$state" ]] && echo "      State: ${state}"
            fi
        done
    elif command -v ifconfig >/dev/null 2>&1; then
        # Fallback to ifconfig
        ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | awk '
            /^[a-z]/ { iface=$1; gsub(/:$/, "", iface) }
            /inet / && !/127.0.0.1/ { print "    " iface ": " $2 }
        '
    else
        echo "    No network info available"
    fi

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

    if command -v git >/dev/null 2>&1; then
        echo "  Git User: $(git config --global user.name 2>/dev/null || echo "not configured")"
        echo "  Git Email: $(git config --global user.email 2>/dev/null || echo "not configured")"
    fi

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
# Health check sections
# ============================================================================

check_zsh_health() {
    log_step "Zsh"
    local issues=0

    check_command "zsh" "zsh" || ((issues++))
    check_directory "Oh My Zsh" "$HOME/.oh-my-zsh" || ((issues++))
    check_directory "Pure prompt" "$HOME/.zsh/pure" || ((issues++))
    check_directory "zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" || ((issues++))
    check_directory "zsh-completions" "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" || ((issues++))
    check_symlink ".zshrc" "$HOME/.zshrc" "${DOTFILES_ROOT}/components/zsh/.zshrc" || ((issues++))

    echo
    return $issues
}

check_git_health() {
    log_step "Git"
    local issues=0

    check_command "git" "git" || ((issues++))
    check_symlink ".gitconfig" "$HOME/.gitconfig" "${DOTFILES_ROOT}/components/git/.gitconfig" || ((issues++))
    check_symlink ".gitignore" "$HOME/.gitignore" "${DOTFILES_ROOT}/components/git/.gitignore" || ((issues++))

    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$git_name" && -n "$git_email" ]]; then
        log_check_pass "user" "$git_name <$git_email>"
    else
        if [[ -z "$git_name" ]]; then
            log_check_fail "user.name" "not configured"
            ((issues++))
        fi
        if [[ -z "$git_email" ]]; then
            log_check_fail "user.email" "not configured"
            ((issues++))
        fi
        log_info "Run: ctdev install git --name 'Your Name' --email 'your@email.com'"
    fi

    echo
    return $issues
}

check_node_health() {
    log_step "Node.js"
    local issues=0

    check_directory "nodenv" "$HOME/.nodenv" || ((issues++))
    check_command "node" "node" || ((issues++))
    check_command "npm" "npm" || ((issues++))

    if command -v npm >/dev/null 2>&1; then
        if npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
            log_check_pass "claude-code" "installed"
        else
            log_check_fail "claude-code" "not installed (optional)"
        fi
    fi

    echo
    return $issues
}

check_ruby_health() {
    log_step "Ruby"
    local issues=0

    if [[ -d "$HOME/.rbenv" ]]; then
        log_check_pass "rbenv" "OK"
    elif command -v ruby >/dev/null 2>&1; then
        log_check_fail "rbenv" "not installed (using system Ruby)"
    else
        log_check_fail "rbenv" "not installed"
        ((issues++))
    fi

    check_command "ruby" "ruby" || ((issues++))
    check_command "gem" "gem" || ((issues++))

    if command -v gem >/dev/null 2>&1; then
        if gem list colorls | grep -q colorls; then
            log_check_pass "colorls" "installed"
        else
            log_check_fail "colorls" "not installed (optional)"
        fi
    fi

    echo
    return $issues
}

check_cli_health() {
    log_step "CLI Tools"
    local issues=0

    check_command "jq" "jq" || ((issues++))
    check_command "gh" "gh" || ((issues++))
    check_command "kubectl" "kubectl" || ((issues++))
    check_command "doctl" "doctl" || ((issues++))
    check_command "helm" "helm" || ((issues++))
    check_command "btop" "btop" || ((issues++))
    check_command "age" "age" || ((issues++))
    check_command "sops" "sops" || ((issues++))
    check_command "terraform" "terraform" || ((issues++))
    check_command "docker" "docker" || ((issues++))
    check_command "tmux" "tmux" || ((issues++))
    check_command "git-spice" "gs" || ((issues++))

    echo
    return $issues
}

check_shell_config_health() {
    log_step "Shell Configuration"
    local issues=0
    local custom_dir="$HOME/.oh-my-zsh/custom"

    if [[ -d "$custom_dir" ]]; then
        check_symlink "aliases.zsh" "$custom_dir/aliases.zsh" "${DOTFILES_ROOT}/shell/aliases.zsh" || ((issues++))
        check_symlink "exports.zsh" "$custom_dir/exports.zsh" "${DOTFILES_ROOT}/shell/exports.zsh" || ((issues++))
        check_symlink "path.zsh" "$custom_dir/path.zsh" "${DOTFILES_ROOT}/shell/path.zsh" || ((issues++))
    else
        log_check_fail "Oh My Zsh custom directory" "not found"
        ((issues++))
    fi

    echo
    return $issues
}

check_apps_health() {
    log_step "Applications"
    local issues=0

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        if [[ -d "/Applications/Visual Studio Code.app" ]] || command -v code >/dev/null 2>&1; then
            log_check_pass "VS Code" "installed"
        else
            log_check_fail "VS Code" "not installed (optional)"
        fi

        if [[ -d "/Applications/Google Chrome.app" ]]; then
            log_check_pass "Chrome" "installed"
        else
            log_check_fail "Chrome" "not installed (optional)"
        fi

        if [[ -d "/Applications/Slack.app" ]]; then
            log_check_pass "Slack" "installed"
        else
            log_check_fail "Slack" "not installed (optional)"
        fi

        if [[ -d "/Applications/Claude.app" ]]; then
            log_check_pass "Claude" "installed"
        else
            log_check_fail "Claude" "not installed (optional)"
        fi

        if [[ -d "/Applications/1Password.app" ]]; then
            log_check_pass "1Password" "installed"
        else
            log_check_fail "1Password" "not installed (optional)"
        fi

        if [[ -d "/Applications/DBeaver.app" ]]; then
            log_check_pass "DBeaver" "installed"
        else
            log_check_fail "DBeaver" "not installed (optional)"
        fi

        if [[ -d "/Applications/TradingView.app" ]]; then
            log_check_pass "TradingView" "installed"
        else
            log_check_fail "TradingView" "not installed (optional)"
        fi

        if [[ -d "/Applications/Linear.app" ]]; then
            log_check_pass "Linear" "installed"
        else
            log_check_fail "Linear" "not installed (optional)"
        fi

        if [[ -d "/Applications/CleanMyMac.app" ]] || [[ -d "/Applications/CleanMyMac_5.app" ]]; then
            log_check_pass "CleanMyMac" "installed"
        else
            log_check_fail "CleanMyMac" "not installed (optional)"
        fi

        if [[ -d "/Applications/logioptionsplus.app" ]]; then
            log_check_pass "Logi Options+" "installed"
        else
            log_check_fail "Logi Options+" "not installed (optional)"
        fi
    else
        # Linux
        if command -v code >/dev/null 2>&1; then
            log_check_pass "VS Code" "installed"
        else
            log_check_fail "VS Code" "not installed (optional)"
        fi

        if command -v google-chrome >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
            log_check_pass "Chrome/Chromium" "installed"
        else
            log_check_fail "Chrome/Chromium" "not installed (optional)"
        fi

        if command -v slack >/dev/null 2>&1 || flatpak list 2>/dev/null | grep -q Slack; then
            log_check_pass "Slack" "installed"
        else
            log_check_fail "Slack" "not installed (optional)"
        fi

        if command -v 1password >/dev/null 2>&1; then
            log_check_pass "1Password" "installed"
        else
            log_check_fail "1Password" "not installed (optional)"
        fi

        if command -v dbeaver >/dev/null 2>&1 || command -v dbeaver-ce >/dev/null 2>&1; then
            log_check_pass "DBeaver" "installed"
        else
            log_check_fail "DBeaver" "not installed (optional)"
        fi

        if command -v tradingview >/dev/null 2>&1 || dpkg -l tradingview &>/dev/null; then
            log_check_pass "TradingView" "installed"
        else
            log_check_fail "TradingView" "not installed (optional)"
        fi
    fi

    echo
    return $issues
}

check_fonts_health() {
    log_step "Fonts"
    local issues=0

    # shellcheck disable=SC2012
    if [[ "$(uname -s)" == "Darwin" ]]; then
        if ls ~/Library/Fonts/*Nerd* >/dev/null 2>&1; then
            local font_count
            font_count=$(find ~/Library/Fonts -name '*Nerd*' 2>/dev/null | wc -l | tr -d ' ')
            log_check_pass "Nerd Fonts" "${font_count} fonts installed"
        else
            log_check_fail "Nerd Fonts" "not installed"
            ((issues++))
        fi
    else
        if ls ~/.local/share/fonts/*Nerd* >/dev/null 2>&1; then
            local font_count
            font_count=$(find ~/.local/share/fonts -name '*Nerd*' 2>/dev/null | wc -l | tr -d ' ')
            log_check_pass "Nerd Fonts" "${font_count} fonts installed"
        elif ls /usr/share/fonts/*Nerd* >/dev/null 2>&1; then
            local font_count
            font_count=$(find /usr/share/fonts -name '*Nerd*' 2>/dev/null | wc -l | tr -d ' ')
            log_check_pass "Nerd Fonts" "${font_count} fonts installed (system)"
        else
            log_check_fail "Nerd Fonts" "not installed"
            ((issues++))
        fi
    fi

    echo
    return $issues
}

check_macos_health() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 0
    fi

    log_step "macOS Defaults"
    local issues=0

    if [[ "$(defaults read com.apple.dock show-recents 2>/dev/null)" == "0" ]]; then
        log_check_pass "Dock settings" "configured"
    else
        log_check_fail "Dock settings" "not configured"
        ((issues++))
    fi

    if [[ "$(defaults read com.apple.finder ShowPathbar 2>/dev/null)" == "1" ]]; then
        log_check_pass "Finder settings" "configured"
    else
        log_check_fail "Finder settings" "not configured"
        ((issues++))
    fi

    if [[ "$(defaults read NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 2>/dev/null)" == "0" ]]; then
        log_check_pass "Keyboard settings" "configured"
    else
        log_check_fail "Keyboard settings" "not configured"
        ((issues++))
    fi

    echo
    return $issues
}

# ============================================================================
# Main command
# ============================================================================

cmd_info() {
    local version
    version=$(get_version)
    local total_issues=0

    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "   SYSTEM REPORT"
    echo "   Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "   ctdev version: ${version}"
    echo "═══════════════════════════════════════════════════════════════"
    echo

    # System information
    show_system_info
    show_hardware_info
    show_environment_details

    # Health checks
    echo "═══════════════════════════════════════════════════════════════"
    echo "   HEALTH CHECKS"
    echo "═══════════════════════════════════════════════════════════════"
    echo

    check_zsh_health || ((total_issues+=$?))
    check_git_health || ((total_issues+=$?))
    check_node_health || ((total_issues+=$?))
    check_ruby_health || ((total_issues+=$?))
    check_cli_health || ((total_issues+=$?))
    check_apps_health || ((total_issues+=$?))
    check_fonts_health || ((total_issues+=$?))
    check_shell_config_health || ((total_issues+=$?))
    check_macos_health || ((total_issues+=$?))

    # Summary
    echo "═══════════════════════════════════════════════════════════════"
    if [[ $total_issues -eq 0 ]]; then
        log_success "All checks passed! Your installation is healthy."
    else
        log_warning "Found $total_issues potential issue(s)"
        echo
        echo "To fix issues, try:"
        echo "  ctdev install <component>    # Reinstall a specific component"
        echo "  ctdev update                 # Update all components"
    fi
    echo "═══════════════════════════════════════════════════════════════"
    echo
}
