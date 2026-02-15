# Zsh Completion for ctdev - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add zsh tab completion for all ctdev commands, flags, component names (with descriptions), and subcommands.

**Architecture:** A single `_ctdev` zsh completion function placed in `components/zsh/completions/`, symlinked to `~/.zfunc/_ctdev` during zsh install. Components are parsed dynamically from `lib/components.sh` using awk. Commands and flags are hardcoded since they change rarely.

**Tech Stack:** Zsh completion system (`_arguments`, `_describe`, `_values`)

---

### Task 1: Create the completion function

**Files:**
- Create: `components/zsh/completions/_ctdev`

**Step 1: Create the completions directory**

```bash
mkdir -p components/zsh/completions
```

**Step 2: Write `components/zsh/completions/_ctdev`**

```zsh
#compdef ctdev

# Zsh completion for ctdev CLI
# Symlinked to ~/.zfunc/_ctdev by components/zsh/install.sh

_ctdev_components() {
    local -a components
    local dotfiles_root

    # Find lib/components.sh relative to the ctdev binary
    local ctdev_bin="${commands[ctdev]:-$(whence -p ctdev 2>/dev/null)}"
    if [[ -n "$ctdev_bin" ]]; then
        # Resolve symlinks to find the real dotfiles root
        dotfiles_root="${ctdev_bin:A:h}"
    fi

    local components_file="${dotfiles_root}/lib/components.sh"

    if [[ -f "$components_file" ]]; then
        # Parse name:description from COMPONENTS array
        while IFS=: read -r name desc _; do
            components+=("${name}:${desc}")
        done < <(awk -F'"' '/^    "/{print $2}' "$components_file")
    fi

    _describe -t components 'component' components
}

_ctdev_configure_targets() {
    local -a targets
    targets=(
        'git:Configure git user (name and email)'
        'macos:Configure macOS system defaults'
        'linux-mint:Configure Linux Mint system defaults'
    )
    _describe -t targets 'target' targets
}

_ctdev_configure_git_opts() {
    _arguments -s \
        '--name[Set git user.name]:name' \
        '--email[Set git user.email]:email' \
        '--local[Configure for current repo only]' \
        '--show[Show current git configuration]' \
        '(-h --help)'{-h,--help}'[Show help]'
}

_ctdev_configure_macos_opts() {
    _arguments -s \
        '--reset[Reset to macOS system defaults]' \
        '--show[Show current macOS configuration]' \
        '(-h --help)'{-h,--help}'[Show help]'
}

_ctdev_configure_linux_mint_opts() {
    _arguments -s \
        '--reset[Reset to Cinnamon system defaults]' \
        '--show[Show current Linux Mint configuration]' \
        '(-h --help)'{-h,--help}'[Show help]'
}

_ctdev_gpu_subcommands() {
    local -a subcommands
    subcommands=(
        'status:Check secure boot and driver signing status'
        'setup:Configure MOK signing for NVIDIA drivers'
        'sign:Sign current NVIDIA kernel modules'
        'info:Show GPU hardware information'
    )
    _describe -t subcommands 'subcommand' subcommands
}

_ctdev() {
    local -a global_flags
    global_flags=(
        '(-h --help)'{-h,--help}'[Show help]'
        '(-v --verbose)'{-v,--verbose}'[Enable verbose output]'
        '(-n --dry-run)'{-n,--dry-run}'[Preview changes without applying]'
        '(-f --force)'{-f,--force}'[Force re-run install scripts]'
        '--version[Show version information]'
    )

    local -a commands
    commands=(
        'install:Install specific components'
        'uninstall:Remove specific components'
        'update:Refresh package metadata'
        'upgrade:Upgrade installed components'
        'list:List components with status'
        'info:Show system information'
        'configure:Configure git, macOS, or Linux Mint settings'
        'gpu:Manage GPU driver signing for Secure Boot'
    )

    _arguments -s \
        "${global_flags[@]}" \
        '1:command:->command' \
        '*::arg:->args'

    case "$state" in
        command)
            _describe -t commands 'ctdev command' commands
            ;;
        args)
            case "${words[1]}" in
                install|uninstall)
                    _arguments -s \
                        "${global_flags[@]}" \
                        '*:component:_ctdev_components'
                    ;;
                upgrade)
                    _arguments -s \
                        "${global_flags[@]}" \
                        '(-y --yes)'{-y,--yes}'[Skip confirmation prompt]' \
                        '*:component:_ctdev_components'
                    ;;
                update)
                    _arguments -s \
                        "${global_flags[@]}" \
                        '--refresh-keys[Re-download APT repository GPG keys]'
                    ;;
                configure)
                    local target="${words[2]}"
                    case "$target" in
                        git) _ctdev_configure_git_opts ;;
                        macos) _ctdev_configure_macos_opts ;;
                        linux-mint) _ctdev_configure_linux_mint_opts ;;
                        *) _ctdev_configure_targets ;;
                    esac
                    ;;
                gpu)
                    _ctdev_gpu_subcommands
                    ;;
                list|info)
                    _arguments -s "${global_flags[@]}"
                    ;;
            esac
            ;;
    esac
}

_ctdev "$@"
```

**Step 3: Commit**

```bash
git add components/zsh/completions/_ctdev
git commit -m "feat: add zsh completion for ctdev"
```

---

### Task 2: Wire up the symlink in install.sh

**Files:**
- Modify: `components/zsh/install.sh:62-67` (after the Pure prompt symlinks section)

**Step 1: Add symlink after Pure prompt setup**

After line 67 (`log_success "Pure prompt installed"`), add:

```bash
# ctdev completions
mkdir -p "$HOME/.zfunc"
safe_symlink "$SCRIPT_DIR/completions/_ctdev" "$HOME/.zfunc/_ctdev"
```

**Step 2: Commit**

```bash
git add components/zsh/install.sh
git commit -m "feat: symlink ctdev completion in zsh install"
```

---

### Task 3: Add cleanup to uninstall.sh

**Files:**
- Modify: `components/zsh/uninstall.sh:21` (before the .zshrc removal)

**Step 1: Add cleanup before .zshrc removal**

Before line 21 (`[[ -L "$HOME/.zshrc" ]] && run_cmd rm -f "$HOME/.zshrc"`), add:

```bash
[[ -L "$HOME/.zfunc/_ctdev" ]] && run_cmd rm -f "$HOME/.zfunc/_ctdev"
```

**Step 2: Commit**

```bash
git add components/zsh/uninstall.sh
git commit -m "feat: clean up ctdev completion in zsh uninstall"
```

---

### Task 4: Verify completion works

**Step 1: Symlink the completion file manually**

```bash
mkdir -p ~/.zfunc
ln -sf "$(pwd)/components/zsh/completions/_ctdev" ~/.zfunc/_ctdev
```

**Step 2: Reload completions and test**

Open a new shell (or run `exec zsh`), then test:

```bash
ctdev <TAB>           # Should show: install, uninstall, update, upgrade, list, info, configure, gpu
ctdev install <TAB>   # Should show component names with descriptions
ctdev configure <TAB> # Should show: git, macos, linux-mint
ctdev gpu <TAB>       # Should show: status, setup, sign, info
ctdev --<TAB>         # Should show: --help, --verbose, --dry-run, --force, --version
```

**Step 3: Squash into single commit**

If all tasks committed separately, squash into one clean commit:

```bash
git rebase -i HEAD~3  # squash the 3 implementation commits
```

Final message: `feat: add zsh completion for ctdev`
