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
ctdev update [component...]     # Update components
ctdev doctor                    # Check installation health
ctdev list                      # List available components
ctdev info                      # Show system information
ctdev uninstall <component...>  # Remove components
ctdev setup                     # Symlink ctdev to ~/.local/bin
```

**Flags:** `--help`, `--dry-run`, `--verbose`, `--version`

**Auto-update:** When running any command, ctdev checks for updates and prompts to pull the latest changes before proceeding.

## Components

| Component | Description |
|-----------|-------------|
| `zsh` | Zsh, Oh My Zsh, Pure prompt, plugins |
| `git` | Git configuration and global gitignore |
| `cli` | CLI tools (jq, gh, kubectl, helm, terraform, btop, docker, etc.) |
| `node` | Node.js via nodenv |
| `ruby` | Ruby via rbenv |
| `apps` | Desktop apps (Chrome, VSCode, Slack, 1Password, etc.) |
| `fonts` | Nerd Fonts (FiraCode, JetBrainsMono, Hack, Ubuntu) |

## Examples

```bash
ctdev install zsh git      # Shell and git config only
ctdev install cli          # CLI tools only
ctdev install --dry-run    # Preview changes
ctdev doctor               # Check installation health
```

## Git Configuration

```bash
ctdev install git                                              # Interactive prompts
./components/git/install.sh --name "Name" --email "email"      # Non-interactive
./components/git/install.sh --skip-user-config                 # Skip user config
```

## DevContainers

Add to `.devcontainer/devcontainer.json`:

```json
{
  "postCreateCommand": "git clone https://github.com/thomasconner/dotfiles ~/dotfiles && ~/dotfiles/ctdev install zsh"
}
```

For additional tools:

```json
{
  "postCreateCommand": "git clone https://github.com/thomasconner/dotfiles ~/dotfiles && ~/dotfiles/ctdev install zsh git cli"
}
```

**Recommended components for DevContainers:**

| Component | Use Case |
|-----------|----------|
| `zsh` | Shell, prompt, aliases (always recommended) |
| `git` | Git config and global gitignore |
| `cli` | CLI tools (gh, jq, etc.) |
| `node` | Node.js development |
| `ruby` | Ruby development |

**Note:** `apps` and `fonts` are desktop-only and should be skipped in DevContainers.

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
