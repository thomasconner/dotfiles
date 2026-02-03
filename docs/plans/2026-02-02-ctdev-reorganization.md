# ctdev Reorganization Design

## Overview

Reorganize ctdev to have apt-like semantics and a flat component structure.

## Goals

1. Clear command semantics (install/uninstall/update/upgrade)
2. Flat component list (no bundled cli/apps)
3. Colored status output in list
4. Separate macos configuration from components

## Commands

| Command | Purpose |
|---------|---------|
| `ctdev install <component...>` | Install specific component(s). Requires at least one argument. |
| `ctdev uninstall <component...>` | Remove specific component(s). |
| `ctdev update` | Refresh metadata only (brew update, git fetch). Fast, no changes. |
| `ctdev upgrade [-y]` | Upgrade installed components. Prompts for confirmation unless -y flag. |
| `ctdev list` | Show all components with colored status. |
| `ctdev info` | System info only (OS, arch, package manager, shell). |
| `ctdev macos [--reset] [--dry-run]` | Configure/reset macOS defaults. Standalone subcommand. |

## Components (32 total)

Flat alphabetical list. Each component has install.sh and uninstall.sh.

```
1password      dbeaver        git-spice      logi-options   sops
age            docker         helm           node           terraform
btop           doctl          jq             ruby           tmux
bun            fonts          kubectl        shellcheck     tradingview
chrome         gh             linear         slack          vscode
cleanmymac     ghostty        git                           zsh
claude-code
```

### Directory Structure

```
components/
  1password/
    install.sh
    uninstall.sh
  age/
    install.sh
    uninstall.sh
  ...
  zsh/
    install.sh
    uninstall.sh

cmds/
  install.sh      # modified - requires component arg
  uninstall.sh    # modified - per-component
  update.sh       # simplified - metadata only
  upgrade.sh      # new - actual upgrades
  list.sh         # modified - colored output
  info.sh         # simplified - system info only
  macos.sh        # new - standalone subcommand
```

## Command Output Examples

### ctdev list

```
$ ctdev list
1password          not installed              # grey
age                installed                  # green
btop               installed (update available)   # yellow
bun                not installed              # grey
chrome             installed                  # green
claude-code        installed                  # green
...
zsh                installed                  # green
```

### ctdev upgrade

```
$ ctdev upgrade
Checking for updates...

The following components will be upgraded:
  btop          1.3.0 → 1.4.0
  gh            2.40.0 → 2.42.0
  node          24.0.0 → 24.1.0

Proceed? [y/N] y

Upgrading btop...
Upgrading gh...
Upgrading node...

Done. 3 components upgraded.
```

### ctdev upgrade -y

```
$ ctdev upgrade -y
Checking for updates...

Upgrading btop...
Upgrading gh...
Upgrading node...

Done. 3 components upgraded.
```

### ctdev update

```
$ ctdev update
Updating package sources...

Homebrew updated
nodenv: 3 new versions available
rbenv: 1 new version available

Done. Run 'ctdev upgrade' to upgrade components.
```

### ctdev info

```
$ ctdev info
OS:              macOS 14.2.1
Architecture:    arm64
Package Manager: brew
Shell:           zsh 5.9
Dotfiles:        ~/Repos/github.com/thomasconner/dotfiles
```

### ctdev macos

```
$ ctdev macos
Configuring macOS defaults...

Setting Dock preferences...
Setting Finder preferences...
Setting keyboard preferences...

Done. Some changes require logout to take effect.

$ ctdev macos --reset
Resetting macOS defaults to system defaults...

Done. Some changes require logout to take effect.
```

## Breaking Changes

| Before | After |
|--------|-------|
| `ctdev install` (no args) installs all | Error - requires component argument |
| `ctdev update` upgrades things | `ctdev update` only refreshes metadata |
| No upgrade command | `ctdev upgrade` does actual upgrades |
| `macos` is a component | `ctdev macos` is a standalone subcommand |
| `claude` is separate component | Merged into `claude-code` |
| `cli` bundles 14 tools | Each tool is its own component |
| `apps` bundles 10 apps | Each app is its own component |

## Migration Notes

- Existing install markers need migration or re-detection
- Users accustomed to `ctdev install` will need to specify components
- `ctdev update` behavior changes significantly

## Implementation Order

1. Restructure components/ directory (move files)
2. Update lib/components.sh with new component list
3. Modify cmds/install.sh (require component arg)
4. Create cmds/upgrade.sh (new command)
5. Simplify cmds/update.sh (metadata only)
6. Simplify cmds/info.sh (system info only)
7. Create cmds/macos.sh (standalone subcommand)
8. Update cmds/list.sh (colored output)
9. Update cmds/uninstall.sh (per-component)
10. Update main ctdev dispatcher
11. Update documentation
