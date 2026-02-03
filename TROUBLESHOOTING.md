# Troubleshooting

## ctdev not found

```bash
./install.sh                    # Re-run install script
export PATH="$HOME/.local/bin:$PATH"
```

## Permission denied

ctdev uses `maybe_sudo` automatically. If you're in Docker without sudo, some installs will fail - check logs for alternatives.

## Component shows as not installed

ctdev uses markers in `~/.config/ctdev/`. If detection fails:

```bash
ctdev install <component>  # Re-run to create marker
```

## Uninstalling

```bash
ctdev uninstall <component...>   # Remove specific components
~/dotfiles/uninstall.sh          # Remove ctdev itself
```

The uninstall script will prompt to remove all components first, then removes the ctdev symlink and config directory.

## macOS

**Xcode popup:** Run `xcode-select --install` manually and wait for it to complete.

**Homebrew not found:** Add to shell profile:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"     # Intel
```

**"Operation not permitted" for defaults:** Grant Terminal full disk access in System Preferences > Security & Privacy.

## Linux

**Fonts not showing:** Run `fc-cache -fv` and restart terminal.

**Package manager not detected:** Run `ctdev info` to see what was detected, then install packages manually.

## Zsh

**Oh My Zsh not loading:** Check `ls -la ~/.zshrc` - should be a symlink. Re-run `ctdev install zsh`.

**Pure prompt missing:** Delete `~/.zsh/pure` and reinstall: `ctdev install zsh --force`.

## Node/Ruby

**Version manager not found:** Add to shell profile:
```bash
export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
```

**Build failing:** Install dependencies first:
```bash
# macOS
brew install openssl readline libyaml

# Ubuntu/Debian
sudo apt install build-essential libssl-dev libyaml-dev zlib1g-dev libffi-dev
```

## Debugging

```bash
ctdev --dry-run install zsh   # Preview without changes
ctdev --verbose install zsh   # More output
ctdev info                    # System diagnostics
ctdev list                    # Show component status
```

## Still stuck?

Open an issue with `ctdev info` output and the failing command.
