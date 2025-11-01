# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modular dotfiles repository for Linux development environments with cross-platform support (v2.0.0). The architecture emphasizes:
- **Idempotent installations**: All scripts can be run multiple times safely
- **Component modularity**: Each component has its own self-contained install script
- **Two deployment modes**: Full desktop installation (`install.sh`) and minimal container installation (`containers.sh`)
- **Cross-platform compatibility**: Supports Ubuntu, Debian, Fedora, Arch, macOS, FreeBSD
- **Docker/container ready**: Works in both root and non-root environments

## Installation Commands

### Full Desktop Installation
```bash
./install.sh [OPTIONS]
```
Installs all components: apps, CLI tools, fonts, git config, Node.js, Ruby, and zsh.

### Container/Minimal Installation
```bash
./containers.sh [OPTIONS]
```
Installs only: CLI tools (jq, gh, kubectl, doctl, helm), git config, and zsh. Excludes desktop apps and fonts.

### Installation Options
All installation scripts support these flags:
- `--dry-run` or `-n`: Preview changes without making modifications
- `--verbose` or `-v`: Enable detailed output and bash debugging
- `--version`: Display version information
- `--help` or `-h`: Show help message

Example:
```bash
./install.sh --dry-run    # Preview what would be installed
./install.sh --verbose    # Show detailed installation steps
```

### Individual Component Installation
```bash
./apps/install.sh      # Desktop apps (Chrome, Slack, VSCode, tmux)
./cli/install.sh       # CLI tools (jq, gh, kubectl, doctl, helm)
./fonts/install.sh     # Nerd Fonts for terminal
./git/install.sh       # Git configuration and aliases
./node/install.sh      # Node.js via nodenv + global packages
./ruby/install.sh      # Ruby via rbenv + colorls gem
./zsh/install.sh       # Zsh, Oh My Zsh, plugins, and shell config
```

Each script handles its own dependencies and will install required tools (git, curl, wget, gpg) as needed.

## Architecture

### Component Structure
Each top-level directory represents a self-contained component:
- `apps/`: Desktop applications with individual install scripts
- `cli/`: Command-line tools (jq, gh, kubectl, doctl, helm)
- `fonts/`: Nerd Fonts installation
- `git/`: Git configuration files (.gitconfig, .gitignore, .gitconfig.local)
- `node/`: Node.js version management via nodenv
- `ruby/`: Ruby version management via rbenv
- `shell/`: Shared shell configuration (aliases.zsh, exports.zsh, path.zsh)
- `zsh/`: Zsh setup including Oh My Zsh and .zshrc
- `scripts/`: Shared utility functions used across install scripts

### Shared Utilities (`scripts/utils.sh`)
Provides reusable functions sourced by all install scripts:

**Dependency Management:**
- `ensure_git_installed()`: Installs git if missing
- `ensure_curl_installed()`: Installs curl if missing
- `ensure_wget_installed()`: Installs wget if missing
- `ensure_gpg_installed()`: Installs gpg if missing
- `ensure_git_repo(url, target_dir)`: Clones or updates a git repository idempotently

**Structured Logging:**
- `log_info(msg)`: Blue [INFO] messages
- `log_success(msg)`: Green [✓] messages
- `log_warning(msg)`: Yellow [WARNING] to stderr
- `log_error(msg)`: Red [ERROR] to stderr
- `log_step(msg)`: Cyan [==>] section headers
- `log_debug(msg)`: Debug messages when VERBOSE=true

**File Management:**
- `backup_file(file)`: Creates timestamped backup before overwriting
- `safe_symlink(source, target)`: Creates symlink with automatic backup
- `cleanup_temp_dir(dir)`: Removes temporary directory safely
- `register_cleanup_trap(dir)`: Registers cleanup on EXIT/INT/TERM

**Cross-Platform Support:**
- `maybe_sudo()`: Runs commands with sudo only if not root (Docker-compatible)
- `detect_os()`: Detects OS (ubuntu, debian, fedora, arch, macos, freebsd)
- `get_package_manager()`: Returns package manager (apt, dnf, pacman, brew, pkg)
- `install_package(name)`: Installs package using correct package manager

**IMPORTANT for Docker/Container Compatibility:**
Always use `maybe_sudo` instead of `sudo` directly. This function detects if running as root (EUID=0) and skips sudo, making scripts work in Docker containers where sudo is not installed.

### Shell Configuration Pattern
The `shell/` directory contains modular zsh configuration:
- `aliases.zsh`: Command aliases and shortcuts
- `exports.zsh`: Shared environment variables (Docker, Git, Go)
- `exports.local.zsh`: Template for user-specific variables (AWS_PROFILE, etc.)
- `path.zsh`: PATH management with deduplication logic

These files are symlinked to `~/.oh-my-zsh/custom/` by `zsh/install.sh`.

**Personal Configuration Pattern:**
User-specific settings go in `.local` files which are:
- Created from templates on first install
- Never overwritten by subsequent installs
- Excluded from git via .gitignore
- Examples: `exports.local.zsh`, `.gitconfig.local`

### Version Management
- **Node.js**: Managed via nodenv (v24.10.0 default)
  - Global packages installed: @anthropic-ai/claude-code, ngrok
  - Location: `~/.nodenv/`
- **Ruby**: Managed via rbenv (v3.4.5 default)
  - Global gems installed: colorls
  - Location: `~/.rbenv/`

### Idempotency Pattern
All install scripts follow this pattern:
1. Check if tool/version is already installed
2. If installed, skip or update (git pull for repos)
3. If missing, install from source or package manager
4. Verify installation and show version

Example from `node/install.sh`:
```bash
if command -v node >/dev/null 2>&1; then
    echo "Node.js is installed: $(node -v)"
else
    # Install nodenv...
fi
```

### Git Configuration
- `.gitconfig`: Main config with aliases, symlinked to `~/.gitconfig`
- `.gitconfig.local`: User-specific settings (name, email), copied to `~/.gitconfig.local` once
- `.gitignore`: Global ignore patterns, symlinked to `~/.gitignore`

The `.gitconfig.local` file is NOT overwritten if it exists, allowing user customization to persist.

### Zsh Plugin Management
Plugins are cloned to `~/.oh-my-zsh/custom/plugins/`:
- zsh-autosuggestions: Auto-suggests commands from history
- zsh-completions: Additional completion definitions

Active plugins configured in `.zshrc`: bundler, common-aliases, docker, git, golang, kubectl, rake, rbenv, ruby, zsh-autosuggestions, zsh-completions

### Pure Prompt Setup
The Pure prompt theme is:
1. Cloned to `~/.zsh/pure/`
2. Symlinked into `~/.zsh/functions/`
3. Loaded via `autoload -U promptinit; promptinit; prompt pure`

## Making Changes

### Adding New Tools
1. Create a new directory or add to existing component (e.g., `cli/`)
2. Write an idempotent install script that:
   - Sources `scripts/utils.sh` for shared functions
   - Checks if already installed before proceeding
   - Handles updates for existing installations
   - Sets `set -e` to fail on errors
3. Add the script to `install.sh` and/or `containers.sh` as appropriate
4. Make the script executable: `chmod +x path/to/install.sh`

### Adding Shell Aliases or Environment Variables
- Aliases: Edit `shell/aliases.zsh`
- Environment variables: Edit `shell/exports.zsh`
- PATH modifications: Edit `shell/path.zsh`

Changes take effect after running `./zsh/install.sh` (which relinks the files) and restarting the shell.

### Updating Version Pins
- Node.js version: Edit `NODE_VERSION` in `node/install.sh`
- Ruby version: Edit `RUBY_VERSION` in `ruby/install.sh`
- Global packages/gems: Edit `NODE_PACKAGES` or `RUBY_GEMS` arrays in respective install scripts

### Application Install Scripts
Application scripts (in `apps/`) follow a standard pattern:
1. Check if command exists: `command -v <tool> >/dev/null 2>&1`
2. If exists, show version and exit
3. If missing, add repository + GPG key, update apt, install
4. Verify installation with version check

See `apps/vscode.sh` or `cli/install.sh` as examples.

## Key Conventions

**Script Structure:**
- All install scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`
  - `-e`: Exit on error
  - `-u`: Exit on undefined variable
  - `-o pipefail`: Exit on pipe failure
- Scripts are idempotent and safe to re-run
- Use structured logging: `log_info`, `log_success`, `log_error` instead of echo
- Use `maybe_sudo` instead of `sudo` for Docker/container compatibility

**File Operations:**
- Symlink configuration files instead of copying (except `.local` files)
- Use `backup_file()` before overwriting existing files
- Use `safe_symlink()` for automatic backup and linking
- Personal configs go in `.local` files that are never overwritten

**Installation Checks:**
- Check for existing installations before attempting to install
- Show versions after installation for verification
- Use `git pull --ff-only` when updating cloned repositories
- Use `ensure_*` utility functions for dependencies

**Testing:**
- Run `./test.sh` for local Docker-based testing (requires Docker)
- GitHub Actions CI runs automatically on push/PR
- ShellCheck linting enforced via CI
- Tests verify all tools install and config files exist

## Version Management

The repository uses semantic versioning tracked in the `VERSION` file:
- Current version: **2.0.0**
- Scripts read this file to display version info with `--version` flag
- Version history:
  - **v2.0.0**: Major refactor with structured logging, cross-platform support, Docker compatibility, dry-run mode, and automated testing
  - **v1.x**: Initial modular dotfiles implementation

## Troubleshooting

**Docker/Container Environments:**
- If you see `sudo: command not found`, ensure scripts use `maybe_sudo` not `sudo`
- If running as root (EUID=0), `maybe_sudo` runs commands directly
- Shell changes (`chsh`) are skipped in Docker/CI environments

**Dry-Run Mode:**
- Use `--dry-run` to preview changes without modifying the system
- Useful for understanding what scripts will do before running them
- Note: Dry-run doesn't create actual installations, so verification steps will fail

**Verbose Mode:**
- Use `--verbose` to see detailed bash execution with `set -x`
- Helpful for debugging installation issues
- Shows all commands as they execute
