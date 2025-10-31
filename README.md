# Dotfiles

A comprehensive dotfiles configuration for Linux development environments, featuring zsh with Oh My Zsh, modern language version managers, and carefully curated shell utilities.

## Features

- **Shell**: zsh with Oh My Zsh framework and Pure prompt
- **Version Management**: Node.js (nodenv) and Ruby (rbenv) with automatic installation
- **Git**: Enhanced configuration with useful aliases and SSH GPG support
- **Terminal**: Optimized for Warp terminal with tmux fallback support
- **Development**: Go, Docker, Kubernetes tooling support
- **Fonts**: Nerd Fonts for enhanced terminal experience

## Quick Start

### Full Installation (Desktop)
```bash
git clone https://github.com/thomasconner/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Container/Minimal Installation
```bash
git clone https://github.com/thomasconner/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./containers.sh
```

### Installation Options
```bash
./install.sh --help        # Show all available options
./install.sh --dry-run     # Preview changes without installing
./install.sh --verbose     # Show detailed output
./install.sh --version     # Show version information
```

### Testing
```bash
./test.sh                  # Run automated tests in Docker
```

### Post-Installation
```bash
omz update  # Update Oh My Zsh (manual step)
```

## New Features (v2.0.0)

### Robustness & Safety
- ✅ **Enhanced Error Handling**: All scripts use `set -euo pipefail` for better error detection
- ✅ **Automatic Cleanup**: Temporary directories cleaned up on exit/failure
- ✅ **File Backups**: Existing config files backed up before modification
- ✅ **Dry-Run Mode**: Preview changes with `--dry-run` flag
- ✅ **Verbose Mode**: Debug output with `--verbose` flag

### Code Quality
- ✅ **Colored Logging**: Structured logging with levels (INFO, SUCCESS, WARNING, ERROR)
- ✅ **ShellCheck Integration**: Linting configuration for code quality
- ✅ **Automated Testing**: Docker-based tests for Ubuntu 20.04, 22.04, 24.04
- ✅ **GitHub Actions CI**: Automated testing on every commit

### Cross-Platform Support
- ✅ **Multi-OS Detection**: Automatic OS/distribution detection
- ✅ **Package Manager Abstraction**: Works with apt, dnf, pacman, brew, pkg
- ✅ **Platform-Specific Logic**: Handles OS-specific package names

### Developer Experience
- ✅ **Progress Indicators**: Spinner animations for long-running operations
- ✅ **Version Tracking**: Semver versioning with `--version` flag
- ✅ **Help System**: Comprehensive help with `--help` flag
- ✅ **Safe Symlinks**: Backup before overwriting with dry-run support

## Components

### Shell Configuration (`shell/`)
- **aliases.zsh**: System shortcuts and development aliases
  - Blue Water Autonomy SSH shortcuts
  - Enhanced `ls` with colorls
  - Port and environment inspection tools
- **exports.zsh**: Environment variables for AWS, Docker, Git, Go
- **path.zsh**: Intelligent PATH management with deduplication

### Language Version Management
- **Node.js** (`node/`): Managed via nodenv
  - Default: v24.6.0
  - Global packages: @anthropic-ai/claude-code, ngrok
- **Ruby** (`ruby/`): Managed via rbenv  
  - Default: v3.4.5
  - Global gems: colorls (enhanced ls)

### Git Configuration (`git/`)
- **.gitconfig**: Main configuration with aliases and behavior
- **.gitconfig.local**: User-specific settings (name, email)
- Enhanced diff settings and SSH GPG signing support

### Zsh Setup (`zsh/`)
- Oh My Zsh with carefully selected plugins:
  - bundler, docker, git, golang, kubectl
  - zsh-autosuggestions, zsh-completions
- Pure prompt theme for clean, informative display
- Optimized history settings with deduplication

### Applications (`apps/`)
- Chrome, Slack, VSCode, Warp terminal installation scripts
- Platform-specific package management

### Fonts (`fonts/`)
- Nerd Fonts installation for enhanced terminal symbols

## Installation Scripts

Each component has its own `install.sh` script that is:
- **Idempotent**: Safe to run multiple times
- **Incremental**: Updates existing installations rather than reinstalling
- **Dependency-aware**: Installs build dependencies as needed

### Individual Component Installation
```bash
./fonts/install.sh      # Install Nerd Fonts
./git/install.sh        # Git configuration and aliases
./node/install.sh       # Node.js via nodenv + global packages
./ruby/install.sh       # Ruby via rbenv + colorls gem
./shell/install.sh      # Oh My Zsh + Pure prompt
./apps/install.sh       # Desktop applications
./zsh/install.sh        # Zsh plugins and configuration
```

## Shell Features

### Aliases
- `lc`: Enhanced colorized directory listing
- `..`: Quick parent directory navigation
- `envs`: Sorted environment variable listing
- `open-ports`: Show listening network ports
- `path-list`: Display PATH entries line by line

### Environment Variables
- AWS CLI profile configuration
- Go workspace and binary paths
- Enhanced grep coloring
- Docker CLI optimizations

### History Management
- 100,000 command history
- Cross-session history sharing
- Duplicate and space-prefixed command filtering

## Development Environment

### Language Support
- **Go**: GOPATH and GOROOT integration
- **Node.js**: Automatic nodenv initialization and completions
- **Ruby**: Automatic rbenv initialization and completions
- **Docker**: Enhanced completion and aliases
- **Kubernetes**: kubectl plugins and completions

### Git Workflow
- Fast-forward only pulls for cleaner history
- SSH signing with GPG format
- Global gitignore patterns
- Automatic branch pruning

## System Requirements

- **OS**: Linux (Ubuntu/Mint with apt package manager)
- **Shell**: zsh (will be configured automatically)
- **Terminal**: Warp recommended, tmux supported
- **Dependencies**: curl, git, build-essential (auto-installed)

## Architecture

### Modular Design
Each component is self-contained with its own installation script, making it easy to:
- Install only needed components
- Update individual parts
- Customize for different environments (desktop vs container)

### Safety Features
- All scripts check for existing installations
- Idempotent operations prevent conflicts
- Clear separation between system and user configurations

### Container Optimization
The `containers.sh` script provides a minimal installation suitable for Docker containers, excluding desktop-specific components like fonts and GUI applications.

## Customization

### Personal Configuration
Edit `git/.gitconfig.local` for your personal Git settings:
```bash
[user]
  name = Your Name
  email = your.email@example.com
```

### Additional Aliases
Add custom aliases to `shell/aliases.zsh` or create a local override file.

### Environment Variables
Extend `shell/exports.zsh` with project-specific environment variables.

## Maintenance

### Updates
- Run `omz update` periodically to update Oh My Zsh
- Re-run `./install.sh` to update language versions and packages
- Individual components can be updated with their specific install scripts

### Backup
Your original configuration files are typically backed up with `.old` extensions during installation.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on a clean system
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
