# Uninstall & Reset Functionality Design

Date: 2026-01-30

## Overview

Add comprehensive uninstall capabilities to ctdev:
- `ctdev uninstall` (no args) to uninstall all components
- Root `uninstall.sh` script to remove ctdev itself
- `--force` flag for reinstalling components
- Fix inconsistencies across all component scripts

## New Commands & Scripts

### `ctdev uninstall` (no args)

Updates `cmds/uninstall.sh` to allow running without arguments:
- Lists all installed components (using markers + heuristics)
- Asks for confirmation: "Uninstall all N components? [y/N]"
- Uninstalls in reverse install order (dependencies last)
- Shows summary at end

Uninstall order (reverse of install):
```
macos → apps → cli → fonts → ruby → node → claude → git → zsh
```

### Root `uninstall.sh` script

New file at repo root (sibling to `install.sh`):

```bash
#!/usr/bin/env bash
# Removes ctdev and optionally all components

# 1. Ask: "Uninstall all components first? [y/N]"
#    - If yes, runs ctdev uninstall (all)
# 2. Remove ~/.local/bin/ctdev symlink
# 3. Remove ~/.config/ctdev/ directory (markers)
# 4. Print: "ctdev removed. Dotfiles repo still exists at $PWD"
```

Can be run directly: `./uninstall.sh` or `curl ... | bash` for remote uninstall.

### `--force` flag for install

Add to `cmds/install.sh`:
- Skips "already installed" checks
- Re-runs component install script regardless of markers/heuristics
- Useful for fixing broken installs
- Passes `FORCE=true` environment variable to component scripts

## Missing Uninstall Functions

### `claude` component uninstall

Add to `cmds/uninstall.sh`:

```bash
uninstall_claude() {
  log_step "Uninstalling claude configuration"

  local claude_dir="$HOME/.claude"

  # Remove CLAUDE.md symlink
  if [[ -L "$claude_dir/CLAUDE.md" ]]; then
    run_cmd rm "$claude_dir/CLAUDE.md"
  fi

  # Remove settings.json symlink
  if [[ -L "$claude_dir/settings.json" ]]; then
    run_cmd rm "$claude_dir/settings.json"
  fi

  # Keep: settings.local.json (user's personal settings)
  # Keep: ~/.claude directory itself (Claude Code uses it)

  log_success "Claude configuration uninstalled"
  log_info "Note: ~/.claude directory preserved (used by Claude Code)"
}
```

### Improve `cli` uninstall

- Actually remove tools installed to `/usr/local/bin` on Linux
- Track which tools were installed via direct download in manifest file
- Manifest location: `~/.config/ctdev/cli-direct-installs.txt`

### `apps` uninstall

- Keep as guidance-only (apps managed by Homebrew/package managers)
- Too risky to auto-remove user applications

## Standardized Install Script Patterns

### Standard template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing {component}"

# Standard early-exit check (skip if FORCE=true)
if [[ "${FORCE:-false}" != "true" ]]; then
  if {component_specific_check}; then
    log_info "{component} is already installed"
    exit 0
  fi
fi

# DRY_RUN: Use run_cmd for all state-changing operations

# Installation logic using run_cmd and safe_symlink
```

### Pattern changes

| Pattern | Current | Standardized |
|---------|---------|--------------|
| Early exit | Always exits | Respects `FORCE` env var |
| DRY_RUN | Top-level exit in some | Use `run_cmd` throughout |
| Symlinks | Mix of `ln -sf` and `safe_symlink` | Always `safe_symlink` |
| DOTFILES_ROOT | Some use inline | Consistent variable at top |

## File Changes

### New files

- `uninstall.sh` (root) - Bootstrap script to remove ctdev

### Modified files

| File | Changes |
|------|---------|
| `cmds/uninstall.sh` | Add `claude` uninstall, support no-args, improve `cli` uninstall |
| `cmds/install.sh` | Add `--force` flag support |
| `lib/cli.sh` | Add `--force` to help text |
| `lib/components.sh` | Add helper to list installed components |
| `components/cli/install.sh` | Track direct installs to manifest |
| All `components/*/install.sh` | Standardize patterns |
| `CLAUDE.md` | Document standardized patterns |

## CLI Manifest

Location: `~/.config/ctdev/cli-direct-installs.txt`

- One tool per line
- Written when tool installed via direct download (not package manager)
- Read during uninstall to know what to remove from `/usr/local/bin`

## Testing

- Use `--dry-run` to verify each uninstall function
- Test on both macOS and Linux paths
