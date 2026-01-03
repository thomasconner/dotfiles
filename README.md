# dotfiles

Modular dotfiles for macOS and Linux. Managed via the `ctdev` CLI.

## Install

```bash
git clone https://github.com/thomasconner/dotfiles.git ~/dotfiles
~/dotfiles/ctdev setup
~/dotfiles/ctdev install
```

## ctdev CLI

```bash
ctdev install [component...]    # Install components (all if none specified)
ctdev update [component...]     # Update system and installed components
ctdev info                      # Show system info and check installation health
ctdev list                      # List available components
ctdev uninstall <component...>  # Remove components
ctdev setup                     # Symlink ctdev to ~/.local/bin
```

**Flags:** `--help`, `--dry-run`, `--verbose`, `--version`

**Update flags:** `--skip-system` (skip system package updates)

**Auto-update:** When running any command, ctdev checks for updates and prompts to pull the latest changes before proceeding.

## Components

| Component | Description                                                                                               |
| --------- | --------------------------------------------------------------------------------------------------------- |
| `zsh`     | Zsh, Oh My Zsh, Pure prompt, plugins                                                                      |
| `git`     | Git configuration and global gitignore                                                                    |
| `cli`     | CLI tools (jq, gh, kubectl, helm, terraform, btop, docker, git-spice, etc.)                               |
| `node`    | Node.js via nodenv                                                                                        |
| `ruby`    | Ruby via rbenv                                                                                            |
| `apps`    | Desktop apps (Chrome, VSCode, Slack, 1Password, etc.)                                                     |
| `fonts`   | Nerd Fonts (FiraCode, JetBrainsMono, Hack, Ubuntu) - configure your terminal to use a Nerd Font for icons |
| `macos`   | macOS system defaults (Dock, Finder, keyboard) - run explicitly with `ctdev install macos`                |

## Examples

```bash
ctdev install zsh git      # Shell and git config only
ctdev install cli          # CLI tools only
ctdev install --dry-run    # Preview changes
ctdev info                 # Check system info and installation health
```

## Git Configuration

```bash
ctdev install git                                              # Interactive prompts
./components/git/install.sh --name "Name" --email "email"      # Non-interactive
./components/git/install.sh --skip-user-config                 # Skip user config
```

## DevContainers

### VS Code Dotfiles Feature

Add to your VS Code `settings.json`:

```json
{
  "dotfiles.repository": "https://github.com/thomasconner/dotfiles.git",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "./devcontainer.sh"
}
```

This automatically installs zsh, Oh My Zsh, and Pure prompt in all your devcontainers.

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
├── components/        # Installable components
└── shell/             # Shell config files
```

## Customization

- `shell/aliases.zsh` - Command aliases
- `shell/exports.zsh` - Environment variables
- `shell/path.zsh` - PATH configuration
- `~/.gitconfig.local` - Git user config (auto-generated)

## License

MIT
