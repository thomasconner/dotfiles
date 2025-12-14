# Changelog

All notable changes to this project will be documented in this file.

## [5.1.0] - 2024-12-14

### Added
- New `macos` component for configuring macOS system defaults (Dock, Finder, keyboard, dialogs, security)
- GitHub CLI extensions update in `ctdev update cli`

## [5.0.6] - 2024-12-12

### Added
- `devcontainer.sh` for VS Code dotfiles integration (supports `dotfiles.installCommand` setting)

## [5.0.5] - 2024-12-11

### Fixed
- Nerd Fonts installation on macOS with Bash 3.2 (replaced `${VAR,,}` with `tr` for lowercase conversion)
- Added detection for manually installed fonts to avoid Homebrew cask conflicts

### Added
- Terminal configuration instructions printed after fonts installation (iTerm2, Terminal.app, VS Code)

## [5.0.4] - 2024-12-11

### Added
- Auto-update check: ctdev now checks if the repo is behind origin before running any command and prompts to pull the latest changes

## [5.0.3] - 2024-12-10

### Added
- DBeaver Community Edition installer with macOS (Homebrew), Debian/Ubuntu (apt), Fedora (dnf), and Arch (pacman) support

## [5.0.2] - 2024-12-10

### Fixed
- Fonts installation failing with SIGPIPE (exit 141) due to find | head pipeline

## [5.0.1] - 2024-12-10

### Fixed
- gh.sh and terraform.sh no longer require lsb_release
- Git component verification in CI uses correct file paths
- DevContainers documentation expanded with examples

### Changed
- GitHub Actions workflow updated for ctdev CLI
- Removed ShellCheck (false positives on zsh config files)

## [5.0.0] - 2024-12-10

### Added
- `ctdev` unified CLI with subcommands (install, update, doctor, list, info, uninstall, setup)
- `ctdev setup` command to symlink ctdev to ~/.local/bin
- `ctdev doctor` command to check installation health
- `ctdev list` command to show available components
- Modular CLI tools installation (individual scripts per tool)
- Git user config with interactive prompts and CLI arguments
- Support for Homebrew-installed nodenv/rbenv (skips git updates)
- Nerd Fonts installation via Homebrew casks on macOS

### Changed
- Reorganized directory structure: components/, cmds/, lib/
- Moved all component installers to components/ directory
- CLI tools now installed individually (age, btop, docker, doctl, gh, helm, jq, kubectl, sops, terraform)
- Node.js uses `brew install nodenv` on macOS, git clone on Linux
- Ruby uses `brew install rbenv` on macOS, git clone on Linux
- Fonts use Homebrew casks on macOS, GitHub releases on Linux
- PATH configuration prioritizes ~/.local/bin
- Symlink resolution in ctdev supports being called via symlink

### Removed
- Old top-level install.sh, update.sh, report.sh, devcontainer.sh
- Old directory structure (apps/, cli/, fonts/, git/, node/, ruby/, zsh/ at root)
- scripts/utils.sh (moved to lib/utils.sh)

## [4.0.0] - 2024-12-10

### Added
- Initial ctdev CLI structure
- Component-based architecture

## [3.0.0] - 2024

### Added
- Cross-platform support (Ubuntu, Debian, Fedora, Arch, macOS, FreeBSD)
- Structured logging functions
- Dry-run mode
- maybe_sudo for Docker compatibility

## [2.0.0] - 2024

### Added
- Modular component installers
- Shared utilities (scripts/utils.sh)

## [1.0.0] - 2024

### Added
- Initial dotfiles implementation
