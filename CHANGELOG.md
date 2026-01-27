# Changelog

All notable changes to this project will be documented in this file.

## [5.11.1] - 2026-01-27

### Fixed
- `ctdev info` now checks `claude` CLI in CLI Tools section (moved from Node.js npm check)
- `ctdev info` now checks `path.zsh` in correct location (`~/.zsh/` instead of `~/.oh-my-zsh/custom/`)
- Added Claude component health check for config symlinks

### Changed
- Updated project CLAUDE.md with `claude` and `macos` components
- Added Claude Code troubleshooting section to TROUBLESHOOTING.md

## [5.11.0] - 2026-01-27

### Added
- New `claude` component for syncing Claude Code configuration across machines
- Symlinks `~/.claude/CLAUDE.md`, `settings.json`, and `settings.local.json` from dotfiles repo

## [5.10.2] - 2026-01-27

### Fixed
- Consolidated all PATH setup in `path.zsh` to fix "nodenv: command not found" error
- nodenv/rbenv bin directories are now added to PATH before running their init scripts

## [5.10.1] - 2026-01-26

### Fixed
- PATH ordering: source path.zsh last so `~/.local/bin` takes precedence over nodenv/rbenv shims

## [5.10.0] - 2026-01-26

### Added
- Claude Code CLI installation via native installer (`curl -fsSL https://claude.ai/install.sh | bash`)

### Removed
- Deprecated npm-based Claude Code installation from node component

## [5.9.1] - 2026-01-18

### Removed
- Linux Mint version upgrade detection from `ctdev update`

## [5.9.0] - 2026-01-16

### Added
- Linux Mint version upgrade detection in `ctdev update` (checks if mintupgrade is available)

### Changed
- Ghostty config: set default window size to 180x80, removed copy/paste keybinds (use defaults)

## [5.8.0] - 2026-01-12

### Added
- One-liner install script: `curl -fsSL https://raw.githubusercontent.com/thomasconner/dotfiles/main/install.sh | bash`

## [5.7.1] - 2026-01-12

### Fixed
- `ctdev gpu status` now correctly detects loaded NVIDIA driver (fixed SIGPIPE issue with pipefail)
- `ctdev gpu status` now correctly detects enrolled MOK keys (fixed fingerprint matching)

## [5.7.0] - 2026-01-12

### Added
- Ghostty terminal emulator installer (cross-platform)
- Ghostty configuration with `ctrl+c`/`ctrl+v` copy/paste keybindings
- `--force` flag to bypass already-installed checks
- Ghostty health check in `ctdev info`

### Changed
- Replaced iTerm2 with Ghostty as the default terminal app
- Updated Nerd Fonts instructions for Ghostty configuration

### Fixed
- Use official ghostty-ubuntu install script for Ubuntu/Debian
- Detect Ubuntu base codename for Linux Mint in Ghostty install

## [5.6.0] - 2026-01-03

### Added
- `ctdev update` command for updating system packages and installed components
- Update detection in `ctdev install` - checks git repos for available updates
- Interactive prompt when updates are available during install

### Changed
- `ctdev install` now only installs new components (no longer auto-updates)
- When already-installed components have updates, user is prompted to update now or defer
- `--skip-system` flag moved to `ctdev update` (deprecated in install)

## [5.5.5] - 2025-12-28

### Fixed
- Silence ShellCheck SC2140 false positive for git URL rewrite syntax in `lib/github.sh`
- Updated CLAUDE.md to reflect current `lib/` directory structure (7 modular files)
- Removed hardcoded version from CLAUDE.md overview

### Changed
- Simplified README.md DevContainers section

## [5.5.4] - 2025-12-28

### Fixed
- `ctdev info` now filters all `/boot*` mounts on Linux (was only filtering `/boot/efi`)
- Simplified disk mount labels (changed "Root (/)" to just "/")

## [5.5.3] - 2025-12-27

### Fixed
- `devcontainer.sh` now runs install script directly (bypasses partial install detection)
- Git clone/pull in devcontainers now forces HTTPS to avoid SSH key issues with URL rewrites

## [5.5.2] - 2025-12-27

### Fixed
- `devcontainer.sh` now skips system package updates that require sudo
- `maybe_sudo` gracefully handles containers with "no new privileges" flag
- zsh install skips `chsh` in devcontainers (shell managed by container)
- Clear error message when zsh not installed in devcontainer

### Added
- `is_devcontainer()` helper detects VS Code devcontainers, Codespaces, and custom containers

## [5.5.1] - 2025-12-27

### Fixed
- `ctdev info` now filters out system volumes on macOS (was showing 10+ unnecessary mounts)
- `ctdev info` now filters out snap/loop/docker mounts on Linux
- `ctdev info` now shows memory used/available on macOS (was only showing total)
- `ctdev info` network section now correctly displays active interfaces on macOS

### Added
- `.zshrc` now sources `~/.secrets` for sensitive credentials (keeps secrets out of git)

## [5.5.0] - 2025-12-26

### Changed
- Merged `ctdev update` into `ctdev install` - single command now handles both installation and updates
- Components not installed will be installed; components already installed will be updated
- System package updates (apt/brew/dnf/pacman) run by default with `--skip-system` flag to skip
- All dry-run messages now visible without `--verbose` flag (use `log_info` instead of `log_debug`)
- Standardized `[DRY-RUN]` prefix (with hyphen) across all scripts

### Added
- `--skip-system` flag for `ctdev install` to skip system package updates
- ShellCheck linting job in GitHub Actions workflow

### Removed
- `ctdev update` command (functionality merged into `ctdev install`)
- `cmds/update.sh` file

## [5.4.0] - 2025-12-26

### Added
- Installation marker files (`~/.config/ctdev/<component>.installed`) for reliable component detection
- TROUBLESHOOTING.md documentation for common issues and solutions
- Enhanced hardware info in `ctdev info`:
  - GPU details via nvidia-smi (model, memory, power, temperature, driver, CUDA version)
  - All mounted disks with usage statistics
  - Network interfaces with IP, MAC address, and state
- Checksum verification for CLI tool downloads (git-spice, doctl, helm, sops)
- Input validation for git user configuration
- ShellCheck static analysis tool to CLI component

### Changed
- Refactored `lib/utils.sh` into modular files:
  - `lib/logging.sh` - Color configuration and log functions
  - `lib/platform.sh` - OS/architecture detection, package management
  - `lib/packages.sh` - Dependency management helpers
  - `lib/github.sh` - GitHub API, checksums, git repository functions
- Memory display now uses binary units (GB = 1024³) for accurate reporting
- Hardware info sections now use consistent indented formatting

### Fixed
- Memory calculation now correctly shows binary units (was showing ~64.8 GB for 64 GB RAM)
- Added 30-second timeout on interactive prompts (prevents CI/CD hangs)
- Non-interactive environments skip update prompts gracefully
- All scripts now pass ShellCheck static analysis

## [5.3.2] - 2025-12-23

### Fixed
- git-spice installer now correctly detects git-spice vs Ghostscript (both use `gs` command)

## [5.3.1] - 2025-12-23

### Added
- git-spice CLI tool for stacked branches workflow (macOS via Homebrew, Linux via GitHub releases)

## [5.3.0] - 2025-12-23

### Changed
- Merged `ctdev doctor` into `ctdev info` - single command now shows system info and health checks
- Moved tmux from `apps` to `cli` component (where it belongs as a CLI tool)

### Removed
- `ctdev doctor` command (functionality merged into `ctdev info`)
- Cursor AI editor app (removed from apps component)

### Fixed
- tmux no longer shows redundant "installation complete" message when already installed

## [5.2.0] - 2025-12-23

### Added
- Cursor AI editor installation for macOS (Homebrew) and Linux (AppImage)
- Comprehensive app checks in `ctdev doctor` for all installed apps (Cursor, Claude, 1Password, DBeaver, TradingView, Linear, CleanMyMac, Logi Options+, tmux)
- CLI tool checks for age, sops, terraform, docker in `ctdev doctor`
- Editor version display (code, cursor) in `ctdev info`
- CLI tool version display for age, sops, terraform in `ctdev info`

## [5.1.3] - 2025-12-19

### Fixed
- Logi Options+ app detection path (bundle name is `logioptionsplus.app`)
- TradingView installer now downloads directly from official URLs instead of using Homebrew cask

### Changed
- TradingView installer supports macOS (DMG) and Debian/Ubuntu (deb) with proper installation flows

## [5.1.2] - 2025-12-14

### Added
- `ctdev doctor` now checks apps, fonts, and macOS defaults components
- `log_check_pass` and `log_check_fail` helpers in `lib/utils.sh` for consistent status output

### Changed
- Unified logging across `ctdev info` and `ctdev doctor` using shared check helpers
- Consistent colored checkmark output (green for pass, yellow for fail)

## [5.1.1] - 2025-12-14

### Changed
- `ctdev update` now checks if components are installed before updating
- Shows helpful skip message with install instructions for non-installed components
- Components without update support (git, fonts, apps, macos) show "No update needed" message

### Fixed
- Variable scope bug in `lib/components.sh` that caused incorrect component names in output

## [5.1.0] - 2025-12-14

### Added
- New `macos` component for configuring macOS system defaults (Dock, Finder, keyboard, dialogs, security)
- GitHub CLI extensions update in `ctdev update cli`

## [5.0.6] - 2025-12-12

### Added
- `devcontainer.sh` for VS Code dotfiles integration (supports `dotfiles.installCommand` setting)

## [5.0.5] - 2025-12-11

### Fixed
- Nerd Fonts installation on macOS with Bash 3.2 (replaced `${VAR,,}` with `tr` for lowercase conversion)
- Added detection for manually installed fonts to avoid Homebrew cask conflicts

### Added
- Terminal configuration instructions printed after fonts installation (iTerm2, Terminal.app, VS Code)

## [5.0.4] - 2025-12-11

### Added
- Auto-update check: ctdev now checks if the repo is behind origin before running any command and prompts to pull the latest changes

## [5.0.3] - 2025-12-10

### Added
- DBeaver Community Edition installer with macOS (Homebrew), Debian/Ubuntu (apt), Fedora (dnf), and Arch (pacman) support

## [5.0.2] - 2025-12-10

### Fixed
- Fonts installation failing with SIGPIPE (exit 141) due to find | head pipeline

## [5.0.1] - 2025-12-10

### Fixed
- gh.sh and terraform.sh no longer require lsb_release
- Git component verification in CI uses correct file paths
- DevContainers documentation expanded with examples

### Changed
- GitHub Actions workflow updated for ctdev CLI
- Removed ShellCheck (false positives on zsh config files)

## [5.0.0] - 2025-12-10

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

## [4.0.0] - 2025-12-10

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
