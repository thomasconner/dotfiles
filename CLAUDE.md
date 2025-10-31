# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modular dotfiles repository for Linux development environments (Ubuntu/Mint with apt). The architecture emphasizes:
- **Idempotent installations**: All scripts can be run multiple times safely
- **Component modularity**: Each component has its own self-contained install script
- **Two deployment modes**: Full desktop installation (`install.sh`) and minimal container installation (`containers.sh`)

## Installation Commands

### Full Desktop Installation
```bash
./install.sh
```
Installs all components: apps, CLI tools, fonts, git config, Node.js, Ruby, and zsh.

### Container/Minimal Installation
```bash
./containers.sh
```
Installs only: CLI tools (gh, kubectl, doctl), git config, and zsh. Excludes desktop apps and fonts.

### Individual Component Installation
```bash
./apps/install.sh      # Desktop apps (Chrome, Slack, VSCode, tmux)
./cli/install.sh       # CLI tools (gh, kubectl, doctl)
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
- `cli/`: Command-line tools (gh, kubectl, doctl)
- `fonts/`: Nerd Fonts installation
- `git/`: Git configuration files (.gitconfig, .gitignore, .gitconfig.local)
- `node/`: Node.js version management via nodenv
- `ruby/`: Ruby version management via rbenv
- `shell/`: Shared shell configuration (aliases.zsh, exports.zsh, path.zsh)
- `zsh/`: Zsh setup including Oh My Zsh and .zshrc
- `scripts/`: Shared utility functions used across install scripts

### Shared Utilities (`scripts/utils.sh`)
Provides reusable functions sourced by install scripts:
- `ensure_git_installed()`: Installs git if missing
- `ensure_curl_installed()`: Installs curl if missing
- `ensure_wget_installed()`: Installs wget if missing
- `ensure_gpg_installed()`: Installs gpg if missing
- `ensure_git_repo(url, target_dir)`: Clones or updates a git repository idempotently

### Shell Configuration Pattern
The `shell/` directory contains modular zsh configuration:
- `aliases.zsh`: Command aliases and shortcuts
- `exports.zsh`: Environment variables (AWS, Docker, Git, Go)
- `path.zsh`: PATH management with deduplication logic

These files are symlinked to `~/.oh-my-zsh/custom/` by `zsh/install.sh`.

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

- All install scripts start with `#!/usr/bin/env bash` and `set -e`
- Scripts are idempotent and safe to re-run
- Use `ensure_*` utility functions for dependencies
- Symlink configuration files instead of copying (except `.gitconfig.local`)
- Check for existing installations before attempting to install
- Show versions after installation for verification
- Use `git pull --ff-only` when updating cloned repositories
