# Troubleshooting Guide

Common issues and solutions for the ctdev dotfiles manager.

## Installation Issues

### "Command not found: ctdev"

The `ctdev` command isn't in your PATH.

**Solution:**
```bash
# Run setup to symlink ctdev to ~/.local/bin
./ctdev setup

# Ensure ~/.local/bin is in your PATH
export PATH="$HOME/.local/bin:$PATH"

# Or add to your shell profile:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### "Permission denied" when installing

You may need elevated privileges for system-level installations.

**Solution:**
```bash
# For package manager installs, ctdev uses maybe_sudo automatically
# If still failing, check sudo access:
sudo -v

# For Docker/rootless environments, some installs may fail
# Check specific component logs for alternatives
```

### Component shows as "not installed" after successful install

The heuristic detection may not match your setup. Since v5.4.0, ctdev uses installation markers for reliable detection.

**Solution:**
```bash
# Check if marker exists
ls -la ~/.config/ctdev/

# Manually create marker if needed
mkdir -p ~/.config/ctdev
date -Iseconds > ~/.config/ctdev/<component>.installed

# Re-run install to create markers
ctdev install <component>
```

## macOS-Specific Issues

### Xcode Command Line Tools popup won't go away

The installation prompt requires user interaction.

**Solution:**
```bash
# Check if already installed
xcode-select -p

# If not, install manually:
xcode-select --install

# Wait for the dialog to complete
```

### Homebrew not found after installation

Homebrew's shell environment isn't loaded.

**Solution:**
```bash
# For Apple Silicon Macs:
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs:
eval "$(/usr/local/bin/brew shellenv)"

# Add to your shell profile for persistence
```

### "Operation not permitted" for macOS defaults

System Integrity Protection or privacy settings may block changes.

**Solution:**
1. Open System Preferences > Security & Privacy > Privacy
2. Grant Terminal/iTerm full disk access
3. Re-run: `ctdev install macos`

## Linux-Specific Issues

### Package manager not detected

Your distribution may not be recognized.

**Solution:**
```bash
# Check detected OS
ctdev info

# Manually install packages using your distro's package manager
# Then re-run ctdev install
```

### Fonts not showing in terminal

Font cache may need refreshing.

**Solution:**
```bash
# Rebuild font cache
fc-cache -fv

# Restart your terminal application
```

## Shell/Zsh Issues

### Oh My Zsh not loading

The .zshrc symlink may be broken or Oh My Zsh isn't installed.

**Solution:**
```bash
# Check symlink
ls -la ~/.zshrc

# Reinstall zsh component
ctdev install zsh

# Or manually fix:
ln -sf ~/path/to/dotfiles/shell/.zshrc ~/.zshrc
```

### Pure prompt not appearing

Pure theme may not be properly linked.

**Solution:**
```bash
# Check fpath includes Pure
echo $fpath | tr ' ' '\n' | grep pure

# Reinstall Pure
rm -rf ~/.zsh/pure
ctdev install zsh
```

### Plugins not loading (autosuggestions, completions)

Plugin directories may be missing.

**Solution:**
```bash
# Check plugin directories
ls ~/.oh-my-zsh/custom/plugins/

# Reinstall if missing
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-completions
ctdev install zsh
```

## Git Issues

### Git config not applied

The symlink may not be created or is broken.

**Solution:**
```bash
# Check symlink
ls -la ~/.gitconfig

# Check if local config exists
cat ~/.gitconfig.local

# Reinstall git component
ctdev install git
```

### GPG signing not working

GPG key may not be configured or available.

**Solution:**
```bash
# List available keys
gpg --list-secret-keys --keyid-format LONG

# Configure signing key in ~/.gitconfig.local
git config --file ~/.gitconfig.local user.signingkey YOUR_KEY_ID
git config --file ~/.gitconfig.local commit.gpgsign true
```

## Node.js/Ruby Issues

### nodenv/rbenv command not found

Shell initialization may not include the version managers.

**Solution:**
```bash
# Check if installed
ls -la ~/.nodenv
ls -la ~/.rbenv

# Add to shell profile:
echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(nodenv init -)"' >> ~/.zshrc

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc

# Restart shell
exec zsh
```

### Node/Ruby version not installing

Build dependencies may be missing.

**Solution:**
```bash
# For Node.js (node-build):
# macOS:
brew install openssl readline

# Ubuntu/Debian:
sudo apt install -y build-essential libssl-dev

# For Ruby (ruby-build):
# macOS:
brew install openssl readline libyaml

# Ubuntu/Debian:
sudo apt install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev
```

## CLI Tools Issues

### Binary verification failed (checksum mismatch)

Download may be corrupted or the checksums file format changed.

**Solution:**
```bash
# Clean and retry
rm -rf /tmp/ctdev-*
ctdev install cli

# If persistent, check network/proxy settings
# Or install manually from the tool's official release page
```

### Tool installed but version is old

Package manager cache may be stale.

**Solution:**
```bash
# macOS:
brew update && brew upgrade

# Ubuntu/Debian:
sudo apt update && sudo apt upgrade

# Or use ctdev update:
ctdev update cli
```

## Dry Run and Debugging

### Testing changes safely

Use dry-run mode to see what would happen without making changes.

```bash
ctdev --dry-run install
ctdev --dry-run uninstall zsh
```

### Getting verbose output

Enable debug logging for more details.

```bash
ctdev --verbose install cli
```

### Checking system health

Run the doctor command to diagnose issues.

```bash
ctdev doctor
```

## Getting Help

If you're still having issues:

1. Check the [README](README.md) for setup instructions
2. Run `ctdev doctor` to diagnose common problems
3. Open an issue with:
   - Output of `ctdev info`
   - Output of `ctdev doctor`
   - The command that failed and its output
   - Your OS version and architecture
