# CLAUDE.md

Instructions for Claude Code when working with this repository.

## ctdev CLI

```bash
ctdev install [component...]    # Install components (all if none specified)
ctdev update [component...]     # Update system and installed components
ctdev uninstall [component...]  # Remove components (all if none specified)
ctdev info                      # System info and health checks
ctdev list                      # List available components
ctdev setup                     # Symlink ctdev to ~/.local/bin
```

**Flags:** `--help`, `--verbose`, `--dry-run`, `--force`, `--version`

## Components

apps, claude, cli, fonts, git, macos, node, ruby, zsh

macos is excluded from default install order - run explicitly.

## Directory structure

```
lib/           Shared utilities (logging, platform detection, packages)
cmds/          CLI command implementations
components/    Installable components (one dir per component)
shell/         Shell config files (symlinked to ~/.oh-my-zsh/custom/)
```

## Key utilities

- `log_info`, `log_success`, `log_warning`, `log_error`, `log_step`
- `detect_os`, `detect_arch`, `get_package_manager`, `maybe_sudo`
- `safe_symlink`, `run_cmd` (respects DRY_RUN)
- `install_package`, `ensure_git_repo`

## Conventions

- All scripts use `set -euo pipefail`
- Scripts are idempotent
- Use `maybe_sudo` instead of `sudo` for Docker compatibility
- Use `run_cmd` to respect DRY_RUN
- Symlink configs instead of copying

## Adding CLI tools

Create `components/cli/<tool>.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/utils.sh"

log_info "Installing <tool>"

if [[ "${FORCE:-false}" != "true" ]] && command -v <tool> >/dev/null 2>&1; then
    log_info "<tool> already installed"
    exit 0
fi

OS=$(detect_os)
if [[ "$OS" == "macos" ]]; then
    brew install <tool>
else
    install_package <tool>
fi
```

Then add to `components/cli/install.sh`.

## Git commits

Single-line messages only. No footers.

## Releases

1. Commit changes
2. Update CHANGELOG.md
3. Bump VERSION
4. Commit: `docs: update for vX.Y.Z`
5. Tag: `git tag vX.Y.Z`
6. Push: `git push && git push --tags`
7. Create release: `gh release create vX.Y.Z`
