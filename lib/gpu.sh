#!/usr/bin/env bash

# GPU and Secure Boot utilities for ctdev CLI
# Part of the Conner Technology dotfiles

###############################################################################
# Constants
###############################################################################

MOK_DIR="/var/lib/shim-signed/mok"
MOK_PRIV="$MOK_DIR/MOK.priv"
MOK_CERT="$MOK_DIR/MOK.der"
DKMS_CONF_DIR="/etc/dkms/framework.conf.d"
DKMS_CONF="$DKMS_CONF_DIR/sign-modules.conf"
DKMS_SIGN_SCRIPT="/etc/dkms/sign-module.sh"

###############################################################################
# Detection Functions
###############################################################################

# Check if Secure Boot is enabled
# Returns: 0 if enabled, 1 if disabled or unknown
is_secure_boot_enabled() {
    if ! command -v mokutil >/dev/null 2>&1; then
        return 1
    fi

    local sb_state
    sb_state=$(mokutil --sb-state 2>/dev/null)

    if [[ "$sb_state" == *"SecureBoot enabled"* ]]; then
        return 0
    else
        return 1
    fi
}

# Check if NVIDIA kernel module is loaded
# Returns: 0 if loaded, 1 if not
is_nvidia_loaded() {
    # Note: Using grep without -q to avoid SIGPIPE issues with pipefail
    lsmod | grep "^nvidia " >/dev/null 2>&1
}

# Get NVIDIA driver version
# Returns: version string or empty if not available
get_nvidia_driver_version() {
    local version=""
    if command -v nvidia-smi >/dev/null 2>&1 && is_nvidia_loaded; then
        version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1 | grep -v "NVIDIA-SMI has failed" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
    fi
    if [[ -z "$version" ]] && is_nvidia_loaded; then
        version=$(modinfo nvidia 2>/dev/null | grep "^version:" | awk '{print $2}' || true)
    fi
    echo "$version"
}

# Get the current rendering backend
# Returns: "nvidia", "llvmpipe", or "other"
get_rendering_backend() {
    if ! command -v glxinfo >/dev/null 2>&1; then
        echo "unknown"
        return
    fi

    local renderer
    renderer=$(glxinfo 2>/dev/null | grep "OpenGL renderer string" | cut -d: -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ "$renderer" == *"llvmpipe"* ]]; then
        echo "llvmpipe"
    elif [[ "$renderer" == *"NVIDIA"* ]] || [[ "$renderer" == *"nvidia"* ]]; then
        echo "nvidia"
    else
        echo "other"
    fi
}

###############################################################################
# MOK/Signing Detection Functions
###############################################################################

# Check if MOK key pair exists
# Returns: 0 if both files exist, 1 if not
mok_key_exists() {
    [[ -f "$MOK_PRIV" ]] && [[ -f "$MOK_CERT" ]]
}

# Check if our MOK key is enrolled in firmware
# Returns: 0 if enrolled, 1 if not
mok_key_enrolled() {
    if ! command -v mokutil >/dev/null 2>&1; then
        return 1
    fi

    if ! mok_key_exists; then
        return 1
    fi

    # Get the fingerprint of our certificate
    local our_fingerprint
    our_fingerprint=$(openssl x509 -inform DER -in "$MOK_CERT" -fingerprint -noout 2>/dev/null | cut -d= -f2)

    if [[ -z "$our_fingerprint" ]]; then
        return 1
    fi

    # Check if it's in the enrolled list (case-insensitive, keep colons for matching)
    # Note: Using grep without -q to avoid SIGPIPE issues with pipefail
    mokutil --list-enrolled 2>/dev/null | grep -i "$our_fingerprint" >/dev/null 2>&1
}

# Check if a kernel module is signed
# Args: $1 = path to .ko file
# Returns: 0 if signed, 1 if not
is_module_signed() {
    local module_path="$1"

    if [[ ! -f "$module_path" ]]; then
        return 1
    fi

    # Check for module signature
    local sig_info
    sig_info=$(modinfo "$module_path" 2>/dev/null | grep -E "^sig_id:|^signer:")

    [[ -n "$sig_info" ]]
}

# Check if DKMS signing is configured
# Returns: 0 if configured, 1 if not
dkms_signing_configured() {
    [[ -f "$DKMS_CONF" ]] && [[ -f "$DKMS_SIGN_SCRIPT" ]]
}

###############################################################################
# Action Functions
###############################################################################

# Find NVIDIA DKMS kernel modules for current kernel
# Returns: list of paths to .ko files (only DKMS modules, not kernel built-ins)
find_nvidia_modules() {
    local kernel_version
    kernel_version=$(uname -r)
    local dkms_path="/lib/modules/$kernel_version/updates/dkms"

    # Only sign DKMS-managed nvidia modules, not kernel built-ins
    if [[ -d "$dkms_path" ]]; then
        find "$dkms_path" \( -name "nvidia*.ko" -o -name "nvidia*.ko.zst" -o -name "nvidia*.ko.xz" \) 2>/dev/null
    fi
}

# Create MOK key pair
# Returns: 0 on success, 1 on failure
create_mok_keypair() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would create MOK key pair at $MOK_DIR"
        return 0
    fi

    # Create directory
    maybe_sudo mkdir -p "$MOK_DIR"

    # Generate key pair
    maybe_sudo openssl req -new -x509 -newkey rsa:2048 \
        -keyout "$MOK_PRIV" \
        -outform DER \
        -out "$MOK_CERT" \
        -days 36500 \
        -subj "/CN=DKMS Module Signing Key/" \
        -nodes 2>/dev/null

    # Set secure permissions on private key
    maybe_sudo chmod 600 "$MOK_PRIV"
    maybe_sudo chmod 644 "$MOK_CERT"
}

# Configure DKMS for automatic module signing
# Returns: 0 on success, 1 on failure
configure_dkms_signing() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure DKMS signing at $DKMS_CONF"
        return 0
    fi

    # Create config directory
    maybe_sudo mkdir -p "$DKMS_CONF_DIR"

    # Write DKMS configuration
    maybe_sudo tee "$DKMS_CONF" > /dev/null << EOF
mok_signing_key="$MOK_PRIV"
mok_certificate="$MOK_CERT"
sign_tool="$DKMS_SIGN_SCRIPT"
EOF

    # Write signing script
    maybe_sudo tee "$DKMS_SIGN_SCRIPT" > /dev/null << 'EOF'
#!/bin/bash
/lib/modules/"$1"/build/scripts/sign-file sha256 "$2" "$3" "$4"
EOF

    maybe_sudo chmod +x "$DKMS_SIGN_SCRIPT"
}

# Sign NVIDIA modules for current kernel
# Returns: 0 on success, 1 on failure
sign_nvidia_modules() {
    local kernel_version
    kernel_version=$(uname -r)
    local sign_file="/lib/modules/$kernel_version/build/scripts/sign-file"

    if [[ ! -x "$sign_file" ]]; then
        log_error "Kernel signing script not found: $sign_file"
        log_info "You may need to install kernel headers: linux-headers-$kernel_version"
        return 1
    fi

    if ! mok_key_exists; then
        log_error "MOK keys not found. Run 'ctdev gpu setup' first."
        return 1
    fi

    local modules
    modules=$(find_nvidia_modules)

    if [[ -z "$modules" ]]; then
        log_warning "No NVIDIA modules found for kernel $kernel_version"
        return 1
    fi

    local signed_count=0
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue

        local module_name
        module_name=$(basename "$module")

        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_info "[DRY-RUN] Would sign: $module_name"
            signed_count=$((signed_count + 1))
            continue
        fi

        # Handle compressed modules
        local actual_module="$module"
        if [[ "$module" == *.zst ]]; then
            actual_module="${module%.zst}"
            maybe_sudo zstd -d -f "$module" -o "$actual_module" 2>/dev/null || true
        elif [[ "$module" == *.xz ]]; then
            actual_module="${module%.xz}"
            maybe_sudo xz -d -k -f "$module" 2>/dev/null || true
        fi

        if maybe_sudo "$sign_file" sha256 "$MOK_PRIV" "$MOK_CERT" "$actual_module" 2>/dev/null; then
            log_check_pass "Signed" "$module_name"
            signed_count=$((signed_count + 1))

            # Re-compress if needed
            if [[ "$module" == *.zst ]]; then
                maybe_sudo zstd -f "$actual_module" -o "$module" 2>/dev/null || true
                maybe_sudo rm -f "$actual_module" || true
            elif [[ "$module" == *.xz ]]; then
                maybe_sudo xz -f "$actual_module" 2>/dev/null || true
            fi
        else
            log_check_fail "Failed to sign" "$module_name"
        fi
    done <<< "$modules"

    if [[ "${DRY_RUN:-false}" != "true" ]]; then
        log_info "Signed $signed_count module(s)"
    fi

    return 0
}

###############################################################################
# GPU Information Functions
###############################################################################

# Display GPU hardware information (shared by info.sh and gpu.sh)
# Works on both Linux and macOS, handles driver not loaded gracefully
show_gpu_hardware_info() {
    local indent="${1:-    }"  # Default 4-space indent

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: use system_profiler
        local gpu_info
        gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset Model:|VRAM|Metal" || true)
        if [[ -n "$gpu_info" ]]; then
            echo "$gpu_info" | while read -r line; do
                echo "${indent}${line}"
            done
        else
            echo "${indent}No GPU information available"
        fi
        return 0
    fi

    # Linux: Check for NVIDIA GPU
    # Note: Using grep without -q to avoid SIGPIPE with pipefail
    local has_nvidia_hw=false
    if command -v lspci >/dev/null 2>&1; then
        local lspci_output
        lspci_output=$(lspci 2>/dev/null || true)
        if echo "$lspci_output" | grep -qi nvidia; then
            has_nvidia_hw=true
        fi
    fi

    if [[ "$has_nvidia_hw" == "true" ]]; then
        # NVIDIA hardware detected
        if is_nvidia_loaded && command -v nvidia-smi >/dev/null 2>&1; then
            # Driver loaded - get detailed info
            local gpu_count=0
            local cuda_version
            cuda_version=$(nvidia-smi 2>&1 | grep "CUDA Version" | grep -oE "CUDA Version: [0-9.]+" | cut -d' ' -f3 || true)

            while IFS=',' read -r name mem_used mem_total power_draw power_cap temp driver; do
                [[ -z "$name" ]] && continue
                gpu_count=$((gpu_count + 1))

                # Trim whitespace safely (no xargs)
                name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                mem_used=$(echo "$mem_used" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                mem_total=$(echo "$mem_total" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                power_draw=$(echo "$power_draw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                power_cap=$(echo "$power_cap" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                temp=$(echo "$temp" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                driver=$(echo "$driver" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

                # Convert MiB to GB
                local mem_used_gb mem_total_gb
                mem_used_gb=$(awk "BEGIN {printf \"%.1f\", $mem_used / 1024}" 2>/dev/null || echo "?")
                mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total / 1024}" 2>/dev/null || echo "?")

                echo "${indent}NVIDIA GPU ${gpu_count}:"
                echo "${indent}  Model: ${name}"
                echo "${indent}  Memory: ${mem_used_gb} GB used / ${mem_total_gb} GB total"
                echo "${indent}  Power: ${power_draw}W / ${power_cap}W"
                echo "${indent}  Temperature: ${temp}C"
                if [[ $gpu_count -eq 1 ]]; then
                    echo "${indent}  Driver: ${driver}"
                    [[ -n "$cuda_version" ]] && echo "${indent}  CUDA: ${cuda_version}"
                fi
            done < <(nvidia-smi --query-gpu=name,memory.used,memory.total,power.draw,power.limit,temperature.gpu,driver_version --format=csv,noheader,nounits 2>/dev/null || true)

            if [[ $gpu_count -eq 0 ]]; then
                # nvidia-smi failed to return data
                local model
                model=$(get_gpu_model)
                echo "${indent}NVIDIA: ${model:-Unknown model}"
                echo "${indent}  Driver: Not responding (try reloading)"
            fi
        else
            # NVIDIA hardware but driver not loaded
            local model
            model=$(get_gpu_model)
            echo "${indent}NVIDIA: ${model:-Unknown NVIDIA GPU}"
            echo "${indent}  Driver: Not loaded"
            local backend
            backend=$(get_rendering_backend)
            if [[ "$backend" == "llvmpipe" ]]; then
                echo "${indent}  Status: Using software rendering (llvmpipe)"
            fi
            if is_secure_boot_enabled; then
                echo "${indent}  Note: Secure Boot enabled - driver may need signing"
            fi
        fi

        # Show any other GPUs (AMD/Intel) via lspci
        if command -v lspci >/dev/null 2>&1; then
            local other_gpus
            other_gpus=$(lspci 2>/dev/null | grep -iE "vga|3d|display" | grep -vi nvidia || true)
            if [[ -n "$other_gpus" ]]; then
                while read -r line; do
                    local gpu_name
                    gpu_name="${line#*: }"
                    echo "${indent}Other: ${gpu_name}"
                done <<< "$other_gpus"
            fi
        fi
    elif command -v lspci >/dev/null 2>&1; then
        # No NVIDIA, show whatever GPUs we find
        local gpu_lines
        gpu_lines=$(lspci 2>/dev/null | grep -iE "vga|3d|display" || true)
        if [[ -n "$gpu_lines" ]]; then
            while read -r line; do
                local gpu_name
                gpu_name="${line#*: }"
                echo "${indent}${gpu_name}"
            done <<< "$gpu_lines"
        else
            echo "${indent}No GPU detected"
        fi
    elif [[ -d /sys/class/drm ]]; then
        # Fallback: check DRM subsystem
        local found=false
        for card in /sys/class/drm/card[0-9]*; do
            if [[ -f "$card/device/vendor" ]]; then
                echo "${indent}GPU detected (install pciutils for details)"
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            echo "${indent}No GPU detected"
        fi
    else
        echo "${indent}No GPU detected or lspci not available"
    fi
}

# Get GPU model name
get_gpu_model() {
    local model=""
    # Only try nvidia-smi if the driver is actually loaded
    if command -v nvidia-smi >/dev/null 2>&1 && is_nvidia_loaded; then
        model=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>&1 | grep -v "NVIDIA-SMI has failed" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
    fi
    # Fallback to lspci for hardware detection
    if [[ -z "$model" ]] && command -v lspci >/dev/null 2>&1; then
        model=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | grep -i nvidia | sed 's/.*: //' | head -1 || true)
    fi
    echo "$model"
}

# Get GPU VRAM info
# Returns: "used/total" in MiB or empty
get_gpu_vram() {
    # Only works when driver is loaded
    if command -v nvidia-smi >/dev/null 2>&1 && is_nvidia_loaded; then
        local vram
        vram=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>&1 | grep -v "NVIDIA-SMI has failed" | head -1 || true)
        if [[ -n "$vram" ]] && [[ "$vram" != *"failed"* ]]; then
            local used total
            used=$(echo "$vram" | cut -d, -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            total=$(echo "$vram" | cut -d, -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            echo "${used}/${total} MiB"
        fi
    fi
}
