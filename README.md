# dotfiles

Modular dotfiles for macOS and Linux. Managed via the `ctdev` CLI.

## Install

**One-liner:**

```bash
curl -fsSL https://raw.githubusercontent.com/thomasconner/dotfiles/main/install.sh | bash
```

**Or manually:**

```bash
git clone https://github.com/thomasconner/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

## ctdev CLI

```bash
ctdev install <component...>    # Install specific components
ctdev uninstall <component...>  # Remove specific components
ctdev update                    # Refresh package metadata
ctdev upgrade [-y]              # Upgrade installed components
ctdev list                      # List components with status
ctdev info                      # Show system information
ctdev configure git             # Configure git user
ctdev configure macos           # Configure macOS defaults
```

**Flags:** `--help`, `--dry-run`, `--verbose`, `--force`, `--version`

## Components

31 components available. Run `ctdev list` to see all with status.

**Desktop Applications:**
1password, chrome, cleanmymac, claude-desktop, dbeaver, ghostty, linear, logi-options, slack, tradingview, vscode

**CLI Tools:**
age, btop, bun, claude-code, docker, doctl, gh, git-spice, helm, jq, kubectl, shellcheck, sops, terraform, tmux

**Configuration & Languages:**
fonts, git, node, ruby, zsh

## Examples

```bash
ctdev install zsh git            # Install shell and git config
ctdev install node bun           # Install Node.js and Bun
ctdev list                       # Show all components with status
ctdev upgrade                    # Upgrade all installed components
ctdev upgrade -y                 # Upgrade without prompting
ctdev configure git              # Configure git user (global)
ctdev configure git --local      # Configure git for current repo
ctdev configure macos            # Configure macOS defaults
ctdev configure macos --reset    # Reset macOS defaults
```

## DevContainers

Add to your VS Code `settings.json`:

```json
{
  "dotfiles.repository": "https://github.com/thomasconner/dotfiles.git",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "./devcontainer.sh"
}
```

This automatically installs zsh, Oh My Zsh, and Pure prompt in devcontainers.

## Platform Support

- **macOS** - Homebrew
- **Ubuntu/Debian** - apt
- **Fedora/RHEL** - dnf
- **Arch** - pacman

## Structure

```
dotfiles/
├── ctdev              # CLI entry point
├── lib/               # Shared utilities
├── cmds/              # CLI commands
└── components/        # Installable components (one dir per component)
```

## Customization

- `components/zsh/aliases.zsh` - Command aliases
- `components/zsh/exports.zsh` - Environment variables
- `components/zsh/path.zsh` - PATH configuration

## Uninstall

```bash
~/dotfiles/uninstall.sh          # Remove ctdev CLI
ctdev uninstall <component...>   # Remove specific components first
```

The uninstall script removes the ctdev symlink and config directory. The dotfiles repo remains at `~/dotfiles` - delete it manually if desired.

## License

MIT
