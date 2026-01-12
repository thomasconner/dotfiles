# ctdev gpu Command Design

**Date:** 2026-01-12
**Status:** Approved

## Overview

Add a `ctdev gpu` command to manage GPU driver signing for Secure Boot compatibility. Solves the problem where CMOS resets or kernel updates cause NVIDIA drivers to become unsigned, forcing fallback to software rendering (llvmpipe).

## Command Structure

```
ctdev gpu <subcommand>

Subcommands:
  status    Check secure boot and driver signing status
  setup     Configure MOK signing for NVIDIA drivers
  sign      Sign current NVIDIA kernel modules
  info      Show GPU hardware information
```

Running `ctdev gpu` with no subcommand shows help.

## Subcommands

### `ctdev gpu status`

Quick health check for GPU driver signing.

**Checks performed:**
1. Secure Boot enabled (via `mokutil --sb-state`)
2. NVIDIA driver loaded (via `lsmod`)
3. Driver signature valid (via `modinfo -F sig_id`)
4. MOK key exists at `/var/lib/shim-signed/mok/`
5. MOK key enrolled (via `mokutil --list-enrolled`)
6. DKMS auto-signing configured

**Output (healthy):**
```
==> GPU Signing Status
[✓] Secure Boot enabled
[✓] NVIDIA driver loaded (nvidia 580.95.05)
[✓] Driver signature valid
[✓] MOK key exists
[✓] MOK key enrolled
[✓] DKMS auto-signing configured
```

**Output (problem):**
```
==> GPU Signing Status
[✓] Secure Boot enabled
[✗] NVIDIA driver not loaded (falling back to llvmpipe)
[✗] MOK key not found
[✗] DKMS auto-signing not configured

Run 'ctdev gpu setup' to configure driver signing.
```

### `ctdev gpu setup`

One-command setup for MOK signing infrastructure.

**Steps:**
1. Pre-flight checks (Secure Boot enabled, NVIDIA DKMS installed)
2. Create MOK key pair at `/var/lib/shim-signed/mok/`
3. Configure DKMS auto-signing
4. Enroll MOK key via `mokutil --import`
5. Sign current NVIDIA modules
6. Print reboot instructions for MOK Manager

**Key generation:**
```bash
openssl req -new -x509 -newkey rsa:2048 \
  -keyout MOK.priv -outform DER -out MOK.der \
  -days 36500 -subj "/CN=DKMS Module Signing Key/" -nodes
```

**DKMS configuration files:**
- `/etc/dkms/framework.conf.d/sign-modules.conf`
- `/etc/dkms/sign-module.sh`

**Reboot instructions shown after setup:**
```
═══════════════════════════════════════════════════════
REBOOT REQUIRED - MOK Enrollment
═══════════════════════════════════════════════════════

1. Reboot your computer now
2. When "MOK Manager" appears, select "Enroll MOK"
3. Select "Continue"
4. Enter the password you just set
5. Select "Reboot"

After reboot, run 'ctdev gpu status' to verify.
═══════════════════════════════════════════════════════
```

### `ctdev gpu sign`

Manually sign NVIDIA modules for current kernel.

**Use case:** Auto-signing failed after kernel update.

**Steps:**
1. Verify MOK keys exist
2. Find NVIDIA `.ko` modules in `/lib/modules/$(uname -r)/`
3. Sign each with kernel's `sign-file` script

**Output:**
```
==> Signing NVIDIA modules for kernel 6.14.0-37-generic
[✓] Signed nvidia.ko
[✓] Signed nvidia-modeset.ko
[✓] Signed nvidia-drm.ko
[✓] Signed nvidia-uvm.ko

Modules signed. Reload with: sudo modprobe -r nvidia && sudo modprobe nvidia
```

### `ctdev gpu info`

Show GPU hardware details.

**Information:**
- GPU model
- Driver version
- VRAM total/used
- Rendering mode (hardware vs llvmpipe)

**Output:**
```
==> GPU Information
Model:      NVIDIA GeForce RTX 3080
Driver:     580.95.05
VRAM:       10240 MiB (1247 MiB used)
Renderer:   Hardware accelerated
```

## File Structure

```
cmds/gpu.sh       # Command dispatcher + subcommand implementations
lib/gpu.sh        # Shared utility functions
lib/cli.sh        # Modified: add gpu help text
```

## Utility Functions (lib/gpu.sh)

```bash
# Detection
is_secure_boot_enabled()
is_nvidia_loaded()
get_nvidia_driver_version()
get_rendering_backend()

# MOK/Signing
mok_key_exists()
mok_key_enrolled()
is_module_signed()
dkms_signing_configured()

# Actions
create_mok_keypair()
configure_dkms_signing()
sign_nvidia_modules()
find_nvidia_modules()

# Constants
MOK_DIR="/var/lib/shim-signed/mok"
MOK_PRIV="$MOK_DIR/MOK.priv"
MOK_CERT="$MOK_DIR/MOK.der"
DKMS_CONF="/etc/dkms/framework.conf.d/sign-modules.conf"
DKMS_SIGN_SCRIPT="/etc/dkms/sign-module.sh"
```

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Command name | `gpu` | Broader scope for future GPU features |
| Subcommand style | Yes | Cleaner separation, standard CLI pattern |
| MOK location | `/var/lib/shim-signed/mok/` | Conventional location |
| Scope | NVIDIA-only | Solves immediate problem, AMD/Intel rarely need signing |
| Output style | Minimal checkmarks | Consistent with existing `ctdev info` |

## Future Extensions

- Support for other DKMS modules (VirtualBox, etc.)
- `ctdev gpu switch` for hybrid graphics
- `ctdev gpu reset` to remove signing setup
