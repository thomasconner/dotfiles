# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common Commands

### Full Installation
```bash
./install.sh
```
Installs all dotfiles components: fonts, git, node, ruby, shell, tmux, warp, and zsh configurations.

### Container-Specific Installation
```bash
./containers.sh
```
Minimal installation for containers (excludes fonts, tmux, and warp).

### Component-Specific Installation
```bash
./fonts/install.sh      # Install Nerd Fonts
./git/install.sh        # Git configuration and aliases
./node/install.sh       # Node.js via nodenv + global packages
./ruby/install.sh       # Ruby via rbenv + colorls gem
./shell/install.sh      # Oh My Zsh + Pure prompt
./tmux/install.sh       # tmux installation and config
./warp/install.sh       # Warp terminal installation
./zsh/install.sh        # Zsh plugins and configuration
```

### Post-Installation Updates
```bash
omz update  # Update Oh My Zsh (manual step)
```

## Architecture

### Shell Configuration Structure
The dotfiles use a modular Oh My Zsh setup with custom configurations split into separate files:
- **aliases.zsh**: System shortcuts and SSH aliases for Blue Water Autonomy infrastructure
- **exports.zsh**: Environment variables for AWS, Docker, Git, Go, and Grep
- **path.zsh**: PATH management with deduplication and validation
- **.zshrc**: Main zsh configuration with plugins, Pure prompt, history settings, and language version managers

### Language Version Management
- **Node.js**: Managed via nodenv with version 24.6.0 as global default
- **Ruby**: Managed via rbenv with version 3.4.5 as global default
- Both managers auto-install if not present and include build dependencies

### Git Configuration Pattern
Uses a two-file approach for git settings:
- **.gitconfig**: Main configuration with aliases, colors, and behavior
- **.gitconfig.local**: User-specific settings (name, email) - created from template

### tmux Configuration
Minimal configuration focused on intuitive pane splitting:
- `|` for horizontal splits
- `-` for vertical splits
- Mouse support enabled

### Installation Safety
All install scripts are idempotent and check for existing installations before proceeding. They update existing installations rather than reinstalling from scratch.

### Global Packages
- **Node**: @anthropic-ai/claude-code, ngrok
- **Ruby**: colorls (enhanced ls command)

## Environment Context
- Target OS: Linux (Ubuntu/Mint with apt package manager)
- Shell: zsh with Oh My Zsh framework
- Prompt: Pure theme
- Terminal: Warp (with fallback tmux support)
- Development: Go, Node.js, Ruby with version managers
