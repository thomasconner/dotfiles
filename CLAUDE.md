# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modular dotfiles repository for Linux development environments with cross-platform support (v2.0.0). The architecture emphasizes:
- **Idempotent installations**: All scripts can be run multiple times safely
- **Component modularity**: Each component has its own self-contained install script
- **Two deployment modes**: Full desktop installation (`install.sh`) and minimal devcontainer installation (`devcontainer.sh`)
- **Cross-platform compatibility**: Supports Ubuntu, Debian, Fedora, Arch, macOS, FreeBSD, and Ubuntu derivatives (Linux Mint, Pop!_OS, etc.)
- **Docker/container ready**: Works in both root and non-root environments

## Installation Commands

### Full Desktop Installation
```bash
./install.sh [OPTIONS]
```
Installs all components: apps, CLI tools, fonts, git config, Node.js, Ruby, and zsh.

### DevContainer Installation
```bash
./devcontainer.sh [OPTIONS]
```
Minimal installation for VS Code DevContainers. Installs only: zsh, Oh My Zsh, Pure prompt, and shell configuration. Assumes all CLI tools are provided by the devcontainer. Perfect for when you just want a nice terminal prompt without installing development tools.

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
./cli/install.sh       # CLI tools (jq, gh, kubectl, doctl, helm, age, sops, terraform)
./fonts/install.sh     # Nerd Fonts for terminal
./git/install.sh       # Git configuration and aliases
./node/install.sh      # Node.js via nodenv + global packages
./ruby/install.sh      # Ruby via rbenv + colorls gem
./zsh/install.sh       # Zsh, Oh My Zsh, plugins, and shell config
```

Each script handles its own dependencies and will install required tools (git, curl, wget, gpg) as needed.

### Installation Mode Comparison

| Component | `install.sh` | `devcontainer.sh` | Individual Scripts |
|-----------|--------------|-------------------|--------------------|
| Desktop Apps | ✅ | ❌ | `./apps/install.sh` |
| CLI Tools | ✅ | ❌ | `./cli/install.sh` |
| Fonts | ✅ | ❌ | `./fonts/install.sh` |
| Git Config | ✅ | ❌ | `./git/install.sh` |
| Node.js | ✅ | ❌ | `./node/install.sh` |
| Ruby | ✅ | ❌ | `./ruby/install.sh` |
| Zsh/Shell | ✅ | ✅ | `./zsh/install.sh` |

For traditional containers/servers, run individual component scripts as needed instead of using a monolithic installer.

### System Updates
```bash
./update.sh [OPTIONS]
```
Updates all installed components including system packages, dotfiles components, and development tools. Supports the same options as installation scripts.

The update script handles:
- **System packages**: Uses the detected package manager (apt, dnf, pacman, brew, pkg) to upgrade all installed packages and clean up orphaned packages
- **Firmware updates**: Runs fwupdmgr to check and apply firmware updates
- **Oh My Zsh**: Updates the framework and all installed plugins (zsh-autosuggestions, zsh-completions)
- **Pure prompt**: Updates the Pure theme from its git repository
- **Version managers**: Updates nodenv, rbenv, and their plugin managers (node-build, ruby-build)
- **CLI tools**: Updates gh (GitHub CLI) and terraform via package manager, updates age and sops from GitHub releases, provides version info and update links for kubectl, doctl, helm
- **Global packages**: Updates npm global packages and Ruby gems

Example:
```bash
./update.sh --dry-run    # Preview what would be updated
./update.sh --verbose    # Show detailed update steps
```

### System Report
```bash
./report.sh [OPTIONS]
```
Generates a comprehensive system report showing installed tools, hardware, and environment configuration. This is useful for troubleshooting, documentation, or verifying your setup.

The report includes:
- **System Information**: OS distribution, kernel version, architecture, hostname, uptime, load average, and container detection
- **Hardware Information**: CPU model and core count, memory (total/used/available), disk space for root and home partitions
- **Installed Tools**: Versions of all tools from this dotfiles repository including:
  - Package managers: nodenv, rbenv
  - Programming languages: Node.js, npm, Ruby, gem, Go, Python
  - Shell & terminal: zsh, tmux, bash
  - Version control: git, gh (GitHub CLI)
  - CLI tools: jq, kubectl, doctl, helm, age, sops, terraform, Docker
  - Applications: VSCode, Chrome, Slack
  - Global packages: npm globals (@anthropic-ai/claude-code, ngrok) and Ruby gems (colorls)
- **Environment Details**: Current shell, default shell, package manager, OS type, user info, terminal info, color support, editor, important paths (Oh My Zsh, nodenv, rbenv), Git configuration (user name/email), Docker status, SSH key count

Example:
```bash
./report.sh              # Generate full system report
./report.sh --verbose    # Show debug output
./report.sh --help       # Show help message
```

The script gracefully handles missing tools and failed version checks, making it safe to run on partial installations.

## Architecture

### Component Structure
Each top-level directory represents a self-contained component:
- `apps/`: Desktop applications with individual install scripts
- `cli/`: Command-line tools (jq, gh, kubectl, doctl, helm, age, sops, terraform)
- `fonts/`: Nerd Fonts installation
- `git/`: Git configuration files (.gitconfig, .gitignore, .gitconfig.local)
- `node/`: Node.js version management via nodenv
- `ruby/`: Ruby version management via rbenv
- `shell/`: Shared shell configuration (aliases.zsh, exports.zsh, path.zsh)
- `zsh/`: Zsh setup including Oh My Zsh and .zshrc
- `scripts/`: Shared utility functions used across install scripts

Top-level scripts:
- `install.sh`: Full desktop installation orchestrator
- `devcontainer.sh`: VS Code DevContainer installation (shell/prompt only)
- `update.sh`: Comprehensive update script for all components
- `report.sh`: System report generator showing installed tools, hardware, and environment
- `test.sh`: Docker-based testing framework

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
- `detect_arch()`: Detects CPU architecture (amd64, arm64)
- `get_package_manager()`: Returns package manager (apt, dnf, pacman, brew, pkg)
- `get_brew_prefix()`: Returns Homebrew prefix (/opt/homebrew for Apple Silicon, /usr/local for Intel)
- `is_macos()`: Returns true if running on macOS
- `is_linux()`: Returns true if running on Linux
- `install_package(name)`: Installs package using correct package manager

**macOS-Specific Functions:**
- `ensure_brew_installed()`: Installs Homebrew if missing
- `ensure_xcode_cli_installed()`: Installs Xcode Command Line Tools if missing
- `install_brew_cask(name)`: Installs a Homebrew cask (GUI application)

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

### Updating Existing Tools
Use `./update.sh` to update all components at once, or run it with `--dry-run` to preview updates. The update script is idempotent and safe to run multiple times. For individual component updates, you can:
- Re-run any component's `install.sh` script (they are idempotent)
- Update git-based components manually with `git pull --ff-only` in their directories
- Use package manager directly for system packages

The update script is the recommended approach as it handles all components consistently and provides structured logging.

### Adding New Tools
1. Create a new directory or add to existing component (e.g., `cli/`)
2. Write an idempotent install script that:
   - Sources `scripts/utils.sh` for shared functions
   - Checks if already installed before proceeding
   - Handles updates for existing installations
   - Sets `set -e` to fail on errors
3. Add the script to `install.sh` or call it individually as needed
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

## VS Code DevContainer Integration

### Overview
The `devcontainer.sh` script provides a minimal installation specifically designed for VS Code DevContainers. It follows the principle of separation of concerns:
- **DevContainer features**: Install development tools (git, gh, kubectl, terraform, node, etc.)
- **Dotfiles script**: Install shell aesthetics (zsh, prompt, aliases)

### Setup Options

**Option 1: PostCreateCommand (Recommended)**
Add to your project's `.devcontainer/devcontainer.json`:
```json
{
  "postCreateCommand": "git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles && ~/dotfiles/devcontainer.sh"
}
```

**Option 2: VS Code Dotfiles Setting**
Add to `.devcontainer/devcontainer.json`:
```json
{
  "dotfiles": {
    "repository": "https://github.com/YOUR_USERNAME/dotfiles",
    "targetPath": "~/dotfiles",
    "installCommand": "~/dotfiles/devcontainer.sh"
  }
}
```

### Example DevContainer Configuration
See `.devcontainer/devcontainer.json` for a complete example showing:
- How to install CLI tools via devcontainer features
- How to set zsh as the default terminal
- How to integrate dotfiles automatically

### What Gets Installed
The `devcontainer.sh` script only installs:
1. zsh (if not present)
2. Oh My Zsh framework
3. Pure prompt theme
4. Shell configuration (aliases, exports, path)
5. Zsh plugins (autosuggestions, completions)

It does NOT install:
- CLI tools (kubectl, helm, terraform, gh, etc.) - use devcontainer features
- Language version managers (nodenv, rbenv) - use devcontainer features
- Desktop applications
- Fonts

### Why This Approach?
1. **Faster container creation**: Skips tool installation that devcontainer already provides
2. **No conflicts**: Avoids duplicate or conflicting tool versions
3. **Declarative**: Tools defined in devcontainer.json, not shell scripts
4. **Best practices**: Follows VS Code devcontainer conventions
5. **Idempotent**: Safe to rebuild containers without issues

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

**VS Code DevContainers:**
- Use `./devcontainer.sh` for minimal shell/prompt setup
- This skips CLI tool installation (kubectl, helm, etc.) and only sets up the shell/prompt
- If you need git config, run `./git/install.sh` separately
- The script will skip `chsh` if running in a non-interactive environment
- After installation, run `exec zsh` or restart your terminal to activate zsh
- Add `"postCreateCommand": "./devcontainer.sh"` to your `.devcontainer/devcontainer.json` for automatic setup

**Ubuntu Derivatives (Linux Mint, Pop!_OS, etc.):**
- Scripts automatically detect Ubuntu-based derivatives and use the base Ubuntu codename for repositories
- This is handled by reading `UBUNTU_CODENAME` from `/etc/os-release`
- Example: Linux Mint 22.2 (zara) uses Ubuntu 24.04 (noble) repositories
- If you see repository errors like "does not have a Release file", ensure the script uses the Ubuntu base codename

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

**macOS Installation:**
- Homebrew is required and will be installed automatically if missing
- Xcode Command Line Tools are required for building Ruby and will be installed automatically
- Apple Silicon Macs (M1/M2/M3+) use `/opt/homebrew`, Intel Macs use `/usr/local`
- CLI tools are installed via Homebrew: `brew install jq gh kubectl doctl helm age sops terraform`
- Desktop apps are installed via Homebrew Cask: `brew install --cask google-chrome slack visual-studio-code`
- Fonts are installed to `~/Library/Fonts` (no cache refresh needed on macOS)
- The `path.zsh` file automatically detects and configures Homebrew paths

**macOS-Specific Notes:**
- zsh is the default shell on modern macOS, but the script handles both pre-installed and brew-installed zsh
- If changing the default shell fails, ensure the shell path is in `/etc/shells`
- For Apple Silicon, ensure Rosetta 2 is installed if running any Intel-only binaries
- The update script checks for macOS system updates via `softwareupdate` command
