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

### DevContainer Installation (VS Code)
For VS Code DevContainers, use the minimal setup that only installs shell/prompt:
```bash
git clone https://github.com/thomasconner/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./devcontainer.sh
```

Or add to your `.devcontainer/devcontainer.json`:
```json
{
  "postCreateCommand": "git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles && ~/dotfiles/devcontainer.sh"
}
```

See `.devcontainer/README.md` for complete setup examples.

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

### Updating
```bash
./update.sh                # Update all components
./update.sh --dry-run      # Preview updates
```

### System Report
```bash
./report.sh                # Generate comprehensive system report
./report.sh --verbose      # Report with debug output
```

Generate a detailed report showing:
- **System Info**: OS, kernel, architecture, uptime, load average
- **Hardware**: CPU, memory, disk usage
- **Installed Tools**: Versions of all dotfiles components
- **Environment**: Shell, package manager, Docker status, Git config, SSH keys

## New Features (v2.0.0)

### DevContainer Support
- ✅ **VS Code Integration**: Dedicated `devcontainer.sh` script for DevContainers
- ✅ **Minimal Installation**: Only installs shell/prompt, not CLI tools
- ✅ **Example Configuration**: Complete `.devcontainer/` example with features
- ✅ **Best Practices**: Separates tool installation (features) from shell config (dotfiles)

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

### CLI Tools (`cli/`)
Command-line tools for cloud, containers, and secrets management:
- **jq**: JSON processor
- **gh**: GitHub CLI
- **kubectl**: Kubernetes CLI
- **doctl**: DigitalOcean CLI
- **helm**: Kubernetes package manager
- **age**: File encryption tool
- **sops**: Secrets management
- **terraform**: Infrastructure as code

Note: For DevContainers, use devcontainer features instead of this script.

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

### Top-Level Scripts
- `install.sh`: Full desktop installation (all components)
- `devcontainer.sh`: VS Code DevContainer installation (shell/prompt only)
- `update.sh`: Update all installed components
- `report.sh`: Generate system report
- `test.sh`: Run automated tests

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

- **OS**: Linux (Ubuntu, Debian, Fedora, Arch), macOS, FreeBSD
- **Package Managers**: apt, dnf, pacman, brew, pkg (auto-detected)
- **Shell**: zsh (will be configured automatically)
- **Terminal**: Any modern terminal; Warp recommended, tmux supported
- **Containers**: Works in Docker, VS Code DevContainers (root and non-root)
- **Dependencies**: curl, git, build-essential (auto-installed as needed)

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
- **devcontainer.sh**: Minimal installation for VS Code DevContainers (shell/prompt only)
  - Installs: zsh, Oh My Zsh, Pure prompt, shell configuration
  - Assumes all CLI tools are provided by devcontainer features
  - Perfect for when you just want a nice terminal without tool installation
  - For traditional containers/servers, run individual component scripts as needed (`./cli/install.sh`, `./git/install.sh`, `./zsh/install.sh`)

## Troubleshooting

### VS Code DevContainers
If you're using VS Code DevContainers:
1. Use `./devcontainer.sh` for minimal shell/prompt setup
2. Install CLI tools via devcontainer features (not dotfiles scripts)
3. The script automatically handles root vs non-root containers
4. After installation, run `exec zsh` or restart the terminal
5. See `.devcontainer/README.md` and example `devcontainer.json` for setup

### Container Environments
- Scripts use `maybe_sudo` for Docker/container compatibility
- Shell changes (`chsh`) are skipped in non-interactive environments
- All scripts work in both root and non-root containers

### Ubuntu Derivatives (Linux Mint, Pop!_OS, etc.)
- Scripts automatically detect and use Ubuntu base codenames for repositories
- Example: Linux Mint 22.2 uses Ubuntu 24.04 (noble) repositories
- Ensures compatibility with third-party package repositories

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
```bash
./update.sh              # Update all components (system packages, dotfiles, tools)
./update.sh --dry-run    # Preview what would be updated
./update.sh --verbose    # Show detailed update output
```

The update script handles:
- System package updates (apt, dnf, pacman, brew, etc.)
- Firmware updates (fwupd)
- Oh My Zsh and zsh plugins
- Version managers (nodenv, rbenv)
- CLI tools (gh, kubectl, helm, doctl)
- NPM global packages and Ruby gems

You can also update components individually:
- Run `omz update` to update Oh My Zsh only
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
