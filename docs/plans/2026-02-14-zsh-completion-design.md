# Zsh Completion for ctdev

## Overview

Add zsh tab completion for the ctdev CLI, covering all commands, flags, component names with descriptions, and subcommands.

## Approach

Static completion file that hardcodes the stable command/flag structure and dynamically parses `lib/components.sh` for component names and descriptions.

## File

`components/zsh/completions/_ctdev` — symlinked to `~/.zfunc/_ctdev` during zsh install.

`~/.zfunc` is already in fpath via `.zshrc` line 80.

## Completion Table

| Context | Completions |
|---|---|
| `ctdev <TAB>` | install, uninstall, update, upgrade, list, info, configure, gpu |
| `ctdev install <TAB>` | Component names with descriptions |
| `ctdev uninstall <TAB>` | Component names with descriptions |
| `ctdev upgrade <TAB>` | Component names with descriptions |
| `ctdev configure <TAB>` | git, macos, linux-mint |
| `ctdev configure git <TAB>` | --name, --email, --local, --show |
| `ctdev configure macos <TAB>` | --reset, --show |
| `ctdev configure linux-mint <TAB>` | --reset, --show |
| `ctdev gpu <TAB>` | status, setup, sign, info |
| Any position | --help, --verbose, --dry-run, --force, --version |

## Component Discovery

Parse `lib/components.sh` with awk to extract `name:description` pairs from the COMPONENTS array. Avoids running `ctdev list` (slower, sources all libs).

## Changes

1. Create `components/zsh/completions/_ctdev`
2. Add symlink to `components/zsh/install.sh`
3. Add cleanup to `components/zsh/uninstall.sh`
