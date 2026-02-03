# Uninstall & Reset Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add comprehensive uninstall capabilities and fix inconsistencies across all component scripts.

**Architecture:** Extend existing uninstall command to support no-args (uninstall all), add root uninstall.sh for ctdev removal, add FORCE support to install, and standardize all component scripts.

**Tech Stack:** Bash scripts, existing lib/utils.sh helpers

---

## Task 1: Add `list_installed_components` helper to lib/components.sh

**Files:**
- Modify: `lib/components.sh:173` (add at end)

**Step 1: Add the helper function**

Add to end of `lib/components.sh`:

```bash
# List all currently installed components
list_installed_components() {
    local name
    for name in $(list_components); do
        if is_component_installed "$name"; then
            echo "$name"
        fi
    done
}
```

**Step 2: Verify it works**

Run: `source lib/utils.sh && list_installed_components`
Expected: List of installed component names, one per line

**Step 3: Commit**

```bash
git add lib/components.sh
git commit -m "feat: add list_installed_components helper"
```

---

## Task 2: Add `uninstall_claude` function to cmds/uninstall.sh

**Files:**
- Modify: `cmds/uninstall.sh:216` (before Main command section)

**Step 1: Add the uninstall function**

Add before line 218 (`# Main command`):

```bash
uninstall_claude() {
    log_step "Uninstalling Claude Code configuration"

    local claude_dir="$HOME/.claude"

    if [[ -L "$claude_dir/CLAUDE.md" ]]; then
        log_info "Removing CLAUDE.md symlink..."
        run_cmd rm -f "$claude_dir/CLAUDE.md"
    fi

    if [[ -L "$claude_dir/settings.json" ]]; then
        log_info "Removing settings.json symlink..."
        run_cmd rm -f "$claude_dir/settings.json"
    fi

    if [[ -L "$claude_dir/settings.local.json" ]]; then
        log_info "Removing settings.local.json symlink..."
        run_cmd rm -f "$claude_dir/settings.local.json"
    fi

    log_success "Claude Code configuration removed"
    log_info "Note: ~/.claude directory preserved (used by Claude Code)"
}
```

**Step 2: Add claude to the case statement**

Modify the case statement around line 252 to add claude:

```bash
            claude) uninstall_claude ;;
```

**Step 3: Test dry-run**

Run: `./ctdev uninstall --dry-run claude`
Expected: Shows what would be removed without making changes

**Step 4: Commit**

```bash
git add cmds/uninstall.sh
git commit -m "feat: add claude component uninstall function"
```

---

## Task 3: Support `ctdev uninstall` with no args (uninstall all)

**Files:**
- Modify: `cmds/uninstall.sh:222-236`

**Step 1: Replace the error block with confirmation prompt**

Replace lines 225-236 (the "Require at least one component" block) with:

```bash
    # If no components specified, uninstall all (with confirmation)
    if [[ ${#components[@]} -eq 0 ]]; then
        local installed=()
        while IFS= read -r comp; do
            installed+=("$comp")
        done < <(list_installed_components)

        if [[ ${#installed[@]} -eq 0 ]]; then
            log_info "No components are currently installed"
            return 0
        fi

        log_warning "This will uninstall all ${#installed[@]} components:"
        for comp in "${installed[@]}"; do
            echo "  - $comp"
        done
        echo

        if [[ -t 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
            printf "Are you sure? [y/N] "
            if ! read -r -t 30 answer || [[ ! "$answer" =~ ^[Yy]$ ]]; then
                log_info "Aborted"
                return 0
            fi
        fi

        # Uninstall in reverse order of DEFAULT_INSTALL_ORDER
        local reverse_order
        reverse_order=$(echo "$DEFAULT_INSTALL_ORDER" | tr ' ' '\n' | tac | tr '\n' ' ')
        for comp in $reverse_order; do
            if [[ " ${installed[*]} " == *" $comp "* ]]; then
                components+=("$comp")
            fi
        done
        # Add macos if installed (not in DEFAULT_INSTALL_ORDER)
        if is_component_installed "macos"; then
            components=("macos" "${components[@]}")
        fi
    fi
```

**Step 2: Test dry-run**

Run: `./ctdev uninstall --dry-run`
Expected: Lists installed components, asks for confirmation (skipped in dry-run), shows what would be uninstalled

**Step 3: Commit**

```bash
git add cmds/uninstall.sh
git commit -m "feat: support ctdev uninstall with no args"
```

---

## Task 4: Update uninstall help text in lib/cli.sh

**Files:**
- Modify: `lib/cli.sh:138-165`

**Step 1: Update the help text**

Replace the `show_uninstall_help` function:

```bash
show_uninstall_help() {
    cat << 'EOF'
ctdev uninstall - Remove dotfiles components

Usage: ctdev uninstall [COMPONENT...]

If no components are specified, all installed components will be uninstalled
(with confirmation prompt).

Components:
    apps       Desktop applications
    claude     Claude Code configuration
    cli        CLI tools
    fonts      Nerd Fonts
    git        Git configuration
    macos      macOS system defaults (resets to Apple defaults)
    node       Node.js (nodenv)
    ruby       Ruby (rbenv)
    zsh        Zsh configuration

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -n, --dry-run    Preview changes without applying

Examples:
    ctdev uninstall            Uninstall all components (with confirmation)
    ctdev uninstall ruby       Remove Ruby/rbenv
    ctdev uninstall apps fonts Remove multiple components
    ctdev uninstall --dry-run  Preview what would be uninstalled
EOF
}
```

**Step 2: Commit**

```bash
git add lib/cli.sh
git commit -m "docs: update uninstall help text"
```

---

## Task 5: Create root uninstall.sh script

**Files:**
- Create: `uninstall.sh`

**Step 1: Create the uninstall script**

Create `uninstall.sh` at repo root:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Uninstall script for ctdev dotfiles
# Usage: ./uninstall.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTDEV_SYMLINK="$HOME/.local/bin/ctdev"
CTDEV_CONFIG_DIR="$HOME/.config/ctdev"

echo
echo "  ┌─────────────────────────────────────┐"
echo "  │  ctdev uninstaller                  │"
echo "  └─────────────────────────────────────┘"
echo

# Check if ctdev is installed
if [[ ! -L "$CTDEV_SYMLINK" ]] && [[ ! -d "$CTDEV_CONFIG_DIR" ]]; then
    info "ctdev does not appear to be installed"
    exit 0
fi

# Ask about uninstalling components first
if [[ -t 0 ]]; then
    printf "Uninstall all components first? [y/N] "
    if read -r answer && [[ "$answer" =~ ^[Yy]$ ]]; then
        if [[ -x "$SCRIPT_DIR/ctdev" ]]; then
            "$SCRIPT_DIR/ctdev" uninstall
        else
            warn "Could not run ctdev uninstall (ctdev not executable)"
        fi
    fi
fi

echo

# Remove ctdev symlink
if [[ -L "$CTDEV_SYMLINK" ]]; then
    info "Removing ctdev symlink..."
    rm -f "$CTDEV_SYMLINK"
    success "Removed $CTDEV_SYMLINK"
else
    info "No ctdev symlink found at $CTDEV_SYMLINK"
fi

# Remove config directory (installation markers)
if [[ -d "$CTDEV_CONFIG_DIR" ]]; then
    info "Removing ctdev config directory..."
    rm -rf "$CTDEV_CONFIG_DIR"
    success "Removed $CTDEV_CONFIG_DIR"
else
    info "No ctdev config directory found"
fi

echo
success "ctdev has been uninstalled"
echo
echo "  The dotfiles repo still exists at: $SCRIPT_DIR"
echo "  To remove it completely: rm -rf $SCRIPT_DIR"
echo
```

**Step 2: Make executable**

Run: `chmod +x uninstall.sh`

**Step 3: Test it**

Run: `./uninstall.sh` (answer 'n' to component uninstall)
Expected: Removes symlink and config dir, shows success message

**Step 4: Commit**

```bash
git add uninstall.sh
git commit -m "feat: add root uninstall.sh script for ctdev removal"
```

---

## Task 6: Standardize component install scripts with FORCE support

**Files:**
- Modify: `components/claude/install.sh`
- Modify: `components/zsh/install.sh`
- Modify: `components/node/install.sh`
- Modify: `components/ruby/install.sh`
- Modify: `components/fonts/install.sh`
- Modify: `components/macos/install.sh`

**Step 1: Update components/claude/install.sh**

Replace entire file:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing Claude Code configuration"

# Early exit if already installed (unless FORCE)
if [[ "${FORCE:-false}" != "true" ]]; then
    if [[ -L "$HOME/.claude/CLAUDE.md" ]] && [[ -e "$HOME/.claude/CLAUDE.md" ]]; then
        log_info "Claude Code configuration is already installed"
        exit 0
    fi
fi

# Ensure ~/.claude directory exists
run_cmd mkdir -p "$HOME/.claude"

# Symlink configuration files
safe_symlink "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
safe_symlink "$SCRIPT_DIR/settings.json" "$HOME/.claude/settings.json"
safe_symlink "$SCRIPT_DIR/settings.local.json" "$HOME/.claude/settings.local.json"

log_success "Claude Code configuration complete"
```

**Step 2: Update components/zsh/install.sh**

Add FORCE check after log_step (around line 12):

```bash
# Early exit if already installed (unless FORCE)
if [[ "${FORCE:-false}" != "true" ]]; then
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Zsh is already installed"
        exit 0
    fi
fi
```

Also fix the raw `ln -sf` calls at lines 80-81 to use `safe_symlink`:

```bash
safe_symlink "$HOME/.zsh/pure/pure.zsh" "$HOME/.zsh/functions/prompt_pure_setup"
safe_symlink "$HOME/.zsh/pure/async.zsh" "$HOME/.zsh/functions/async"
```

**Step 3: Update other component scripts similarly**

Each component needs:
1. FORCE check after log_step
2. Replace any raw `ln -sf` with `safe_symlink`
3. Use `run_cmd` for state-changing operations

**Step 4: Test**

Run: `FORCE=true ./ctdev install --dry-run claude`
Expected: Should show it would reinstall even if already present

**Step 5: Commit**

```bash
git add components/
git commit -m "feat: standardize component scripts with FORCE support"
```

---

## Task 7: Standardize CLI tool scripts with FORCE support

**Files:**
- Modify: `components/cli/install.sh`
- Modify: `components/cli/jq.sh`
- Modify: `components/cli/kubectl.sh`
- Modify: All other `components/cli/*.sh` files

**Step 1: Update components/cli/install.sh**

Remove the dry-run early exit (let individual scripts handle it):

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing CLI tools"

# Install each CLI tool via its own script
# FORCE and DRY_RUN are passed through environment
"$SCRIPT_DIR/shellcheck.sh"
"$SCRIPT_DIR/jq.sh"
"$SCRIPT_DIR/gh.sh"
"$SCRIPT_DIR/kubectl.sh"
"$SCRIPT_DIR/doctl.sh"
"$SCRIPT_DIR/helm.sh"
"$SCRIPT_DIR/age.sh"
"$SCRIPT_DIR/sops.sh"
"$SCRIPT_DIR/terraform.sh"
"$SCRIPT_DIR/btop.sh"
"$SCRIPT_DIR/docker.sh"
"$SCRIPT_DIR/tmux/install.sh"
"$SCRIPT_DIR/git-spice.sh"
"$SCRIPT_DIR/claude-code.sh"

log_success "CLI tools installation complete"
```

**Step 2: Update components/cli/jq.sh as template**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_info "Installing jq"

# Early exit if already installed (unless FORCE)
if [[ "${FORCE:-false}" != "true" ]]; then
    if command -v jq >/dev/null 2>&1; then
        log_info "jq is already installed: $(jq --version)"
        exit 0
    fi
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install jq"
    exit 0
fi

log_info "Installing jq..."
install_package jq
log_success "jq installed: $(jq --version)"
```

**Step 3: Apply same pattern to all CLI scripts**

Update each `components/cli/*.sh` file with:
1. FORCE check wrapping the "already installed" check
2. DRY_RUN check before actual installation

**Step 4: Commit**

```bash
git add components/cli/
git commit -m "feat: standardize CLI scripts with FORCE support"
```

---

## Task 8: Update CLAUDE.md with standardized patterns

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add standardized pattern documentation**

Add after "Adding CLI Tools" section:

```markdown
## Standardized Script Patterns

### Component Install Scripts

All component install scripts should follow this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing {component}"

# Early exit if already installed (unless FORCE)
if [[ "${FORCE:-false}" != "true" ]]; then
    if {component_specific_check}; then
        log_info "{component} is already installed"
        exit 0
    fi
fi

# DRY_RUN: use run_cmd for state-changing operations
# Installation logic here...

log_success "{component} installation complete"
```

### Key Patterns

- **FORCE support**: Wrap "already installed" checks with `[[ "${FORCE:-false}" != "true" ]]`
- **DRY_RUN support**: Use `run_cmd` for all state-changing operations
- **Symlinks**: Always use `safe_symlink` helper (never raw `ln -sf`)
- **DOTFILES_ROOT**: Define at top of script, use consistently
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add standardized script patterns"
```

---

## Task 9: Final testing and cleanup

**Step 1: Test full workflow**

```bash
# Test install with force
./ctdev install --force --dry-run claude

# Test uninstall single component
./ctdev uninstall --dry-run git

# Test uninstall all
./ctdev uninstall --dry-run

# Test root uninstall script
./uninstall.sh  # answer 'n' to preserve components
```

**Step 2: Verify all scripts are executable**

Run: `find components -name "*.sh" -exec test -x {} \; -print`
Expected: All .sh files listed (meaning they're all executable)

**Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: cleanup from testing"
```
