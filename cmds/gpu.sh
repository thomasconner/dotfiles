#!/usr/bin/env bash

# ctdev gpu - Manage GPU driver signing for Secure Boot

# Source GPU utilities
source "${DOTFILES_ROOT}/lib/gpu.sh"

###############################################################################
# Subcommand: status
###############################################################################

gpu_status() {
    # macOS doesn't use Secure Boot/MOK signing
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "GPU driver signing is not applicable on macOS."
        log_info "Use 'ctdev gpu info' to see GPU details."
        return 0
    fi

    log_step "GPU Signing Status"

    local issues=0

    # Check Secure Boot
    if is_secure_boot_enabled; then
        log_check_pass "Secure Boot" "enabled"
    else
        log_check_pass "Secure Boot" "disabled (signing not required)"
        echo
        log_info "Secure Boot is disabled. GPU driver signing is not required."
        return 0
    fi

    # Check NVIDIA driver loaded
    local driver_version
    driver_version=$(get_nvidia_driver_version)
    if is_nvidia_loaded; then
        log_check_pass "NVIDIA driver loaded" "$driver_version"
    else
        local backend
        backend=$(get_rendering_backend)
        if [[ "$backend" == "llvmpipe" ]]; then
            log_check_fail "NVIDIA driver not loaded" "falling back to software rendering (llvmpipe)"
        else
            log_check_fail "NVIDIA driver not loaded" "using $backend"
        fi
        issues=$((issues + 1))
    fi

    # Check driver signature (only meaningful if driver is loaded)
    if is_nvidia_loaded; then
        local nvidia_module
        nvidia_module=$(find "/lib/modules/$(uname -r)" -name "nvidia.ko*" 2>/dev/null | head -1)
        if [[ -n "$nvidia_module" ]] && is_module_signed "$nvidia_module"; then
            log_check_pass "Driver signature" "valid"
        else
            log_check_fail "Driver signature" "unsigned or invalid"
            issues=$((issues + 1))
        fi
    fi

    # Check MOK key exists
    if mok_key_exists; then
        log_check_pass "MOK key exists" "$MOK_DIR"
    else
        log_check_fail "MOK key" "not found"
        issues=$((issues + 1))
    fi

    # Check MOK key enrolled
    if mok_key_enrolled; then
        log_check_pass "MOK key enrolled" "in firmware"
    else
        if mok_key_exists; then
            log_check_fail "MOK key" "exists but not enrolled (reboot required)"
        else
            log_check_fail "MOK key" "not enrolled"
        fi
        issues=$((issues + 1))
    fi

    # Check DKMS signing configured
    if dkms_signing_configured; then
        log_check_pass "DKMS auto-signing" "configured"
    else
        log_check_fail "DKMS auto-signing" "not configured"
        issues=$((issues + 1))
    fi

    echo

    if [[ $issues -gt 0 ]]; then
        log_warning "Found $issues issue(s)"
        echo
        echo "Run 'ctdev gpu setup' to configure driver signing."
    else
        log_success "GPU signing is properly configured"
    fi

    return $issues
}

###############################################################################
# Subcommand: setup
###############################################################################

gpu_setup() {
    # macOS doesn't use Secure Boot/MOK signing
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_error "GPU driver signing setup is not applicable on macOS."
        log_info "macOS handles GPU drivers differently and doesn't require MOK signing."
        return 1
    fi

    log_step "GPU Signing Setup"
    echo

    # Pre-flight checks
    if ! is_secure_boot_enabled; then
        log_warning "Secure Boot is disabled. Driver signing is not required."
        echo
        read -rp "Continue anyway? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled."
            return 0
        fi
    fi

    # Check for NVIDIA DKMS
    local dkms_output
    dkms_output=$(dkms status 2>/dev/null || true)
    if ! echo "$dkms_output" | grep -q nvidia; then
        log_error "NVIDIA DKMS module not found."
        log_info "Install the NVIDIA driver via your package manager first."
        return 1
    fi

    # Check if already set up
    if mok_key_exists && dkms_signing_configured; then
        if [[ "${FORCE:-false}" != "true" ]]; then
            log_info "MOK signing is already configured."
            echo
            if mok_key_enrolled; then
                log_success "Setup complete. Your drivers should be properly signed."
                echo
                log_info "To re-sign modules for current kernel, run: ctdev gpu sign"
            else
                log_warning "MOK key exists but is not enrolled in firmware."
                echo
                echo "You need to reboot and enroll the key in MOK Manager."
                echo "Run 'ctdev gpu setup --force' to re-import the key."
            fi
            return 0
        fi
    fi

    # Step 1: Create MOK key pair
    log_step "Creating MOK key pair"
    if mok_key_exists && [[ "${FORCE:-false}" != "true" ]]; then
        log_info "MOK keys already exist at $MOK_DIR"
    else
        if create_mok_keypair; then
            log_success "Created MOK key pair at $MOK_DIR"
        else
            log_error "Failed to create MOK key pair"
            return 1
        fi
    fi
    echo

    # Step 2: Configure DKMS
    log_step "Configuring DKMS auto-signing"
    if configure_dkms_signing; then
        log_success "DKMS signing configured"
    else
        log_error "Failed to configure DKMS signing"
        return 1
    fi
    echo

    # Step 3: Enroll MOK key
    log_step "Enrolling MOK key"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: mokutil --import $MOK_CERT"
    else
        echo "You will be prompted to create a one-time password."
        echo "Remember this password - you'll need it at the next reboot."
        echo
        if maybe_sudo mokutil --import "$MOK_CERT"; then
            log_success "MOK key queued for enrollment"
        else
            log_error "Failed to import MOK key"
            return 1
        fi
    fi
    echo

    # Step 4: Sign current modules
    log_step "Signing NVIDIA modules for kernel $(uname -r)"
    sign_nvidia_modules
    echo

    # Step 5: Print reboot instructions
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
        echo
        echo "═══════════════════════════════════════════════════════════════"
        echo "   REBOOT REQUIRED - MOK Enrollment"
        echo "═══════════════════════════════════════════════════════════════"
        echo
        echo "   1. Reboot your computer now"
        echo "   2. When 'MOK Manager' appears (blue screen), select 'Enroll MOK'"
        echo "   3. Select 'Continue'"
        echo "   4. Enter the password you just set"
        echo "   5. Select 'Reboot'"
        echo
        echo "   After reboot, run 'ctdev gpu status' to verify."
        echo
        echo "═══════════════════════════════════════════════════════════════"
        echo
    fi

    return 0
}

###############################################################################
# Subcommand: sign
###############################################################################

gpu_sign() {
    # macOS doesn't use kernel module signing
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_error "GPU driver signing is not applicable on macOS."
        log_info "macOS handles GPU drivers differently and doesn't require MOK signing."
        return 1
    fi

    local kernel_version
    kernel_version=$(uname -r)

    log_step "Signing NVIDIA modules for kernel $kernel_version"
    echo

    # Check prerequisites
    if ! mok_key_exists; then
        log_error "MOK keys not found at $MOK_DIR"
        log_info "Run 'ctdev gpu setup' first to create signing keys."
        return 1
    fi

    sign_nvidia_modules

    echo
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
        log_info "To reload the driver, run:"
        echo "  sudo modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia && sudo modprobe nvidia"
        echo
        log_info "Or simply reboot your system."
    fi

    return 0
}

###############################################################################
# Subcommand: info
###############################################################################

gpu_info() {
    log_step "GPU Information"
    echo

    # Use shared GPU info function (works on both Linux and macOS)
    show_gpu_hardware_info "  "

    # Secure Boot status (Linux only)
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo
        if is_secure_boot_enabled; then
            echo "  Secure Boot: Enabled"
        else
            echo "  Secure Boot: Disabled"
        fi
    fi

    echo
}

###############################################################################
# Help functions
###############################################################################

show_gpu_help() {
    cat << 'EOF'
ctdev gpu - Manage GPU driver signing for Secure Boot

Usage: ctdev gpu <subcommand> [OPTIONS]

Subcommands:
    status    Check secure boot and driver signing status
    setup     Configure MOK signing for NVIDIA drivers
    sign      Sign current NVIDIA kernel modules
    info      Show GPU hardware information

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
    -f, --force      Force re-run setup even if already configured

Examples:
    ctdev gpu status           Check if driver signing is configured
    ctdev gpu setup            Set up MOK signing (interactive)
    ctdev gpu sign             Re-sign modules after kernel update
    ctdev gpu info             Show GPU hardware details

For Secure Boot systems, NVIDIA drivers must be signed with a Machine Owner
Key (MOK) to load. This command helps configure automatic signing.
EOF
}

show_gpu_status_help() {
    cat << 'EOF'
ctdev gpu status - Check GPU driver signing status

Usage: ctdev gpu status [OPTIONS]

Checks:
    - Secure Boot enabled/disabled
    - NVIDIA driver loaded
    - Driver signature validity
    - MOK key existence and enrollment
    - DKMS auto-signing configuration

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
EOF
}

show_gpu_setup_help() {
    cat << 'EOF'
ctdev gpu setup - Configure MOK signing for NVIDIA drivers

Usage: ctdev gpu setup [OPTIONS]

Sets up Machine Owner Key (MOK) signing infrastructure:
    1. Creates MOK key pair at /var/lib/shim-signed/mok/
    2. Configures DKMS for automatic module signing
    3. Enrolls the MOK key (requires reboot to complete)
    4. Signs current NVIDIA modules

After setup, you must reboot and complete MOK enrollment in the
firmware's MOK Manager screen.

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
    -f, --force      Force re-run even if already configured
EOF
}

show_gpu_sign_help() {
    cat << 'EOF'
ctdev gpu sign - Sign NVIDIA kernel modules

Usage: ctdev gpu sign [OPTIONS]

Signs all NVIDIA kernel modules for the current kernel using the
MOK key. Use this after kernel updates if automatic signing failed.

Requires MOK keys to exist (run 'ctdev gpu setup' first).

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying
EOF
}

show_gpu_info_help() {
    cat << 'EOF'
ctdev gpu info - Show GPU hardware information

Usage: ctdev gpu info [OPTIONS]

Displays:
    - GPU model
    - Driver version
    - VRAM usage
    - Current rendering backend
    - Secure Boot status

Options:
    -h, --help       Show this help message
EOF
}

###############################################################################
# Main command dispatcher
###############################################################################

cmd_gpu() {
    local subcommand="${1:-}"

    # Handle no subcommand
    if [[ -z "$subcommand" ]]; then
        show_gpu_help
        return 0
    fi

    # Shift to get remaining args
    shift

    # Parse subcommand-specific flags
    case "$subcommand" in
        -h|--help)
            show_gpu_help
            return 0
            ;;
        status)
            if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
                show_gpu_status_help
                return 0
            fi
            gpu_status
            ;;
        setup)
            if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
                show_gpu_setup_help
                return 0
            fi
            gpu_setup
            ;;
        sign)
            if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
                show_gpu_sign_help
                return 0
            fi
            gpu_sign
            ;;
        info)
            if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
                show_gpu_info_help
                return 0
            fi
            gpu_info
            ;;
        *)
            log_error "Unknown subcommand: $subcommand"
            echo
            show_gpu_help
            return 1
            ;;
    esac
}
