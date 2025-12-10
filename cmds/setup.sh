#!/usr/bin/env bash

# ctdev setup - Set up ctdev CLI in PATH

cmd_setup() {
    log_step "ctdev setup"

    # Always use ~/.local/bin - no sudo needed, works everywhere
    local target_dir="$HOME/.local/bin"
    mkdir -p "$target_dir"

    local target="$target_dir/ctdev"
    local source="$DOTFILES_ROOT/ctdev"

    log_info "Installing ctdev to $target"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would create symlink: $target -> $source"
    else
        # Remove existing if present
        if [[ -L "$target" ]] || [[ -f "$target" ]]; then
            log_info "Removing existing ctdev..."
            rm -f "$target"
        fi

        # Create symlink
        ln -sf "$source" "$target"
        log_success "ctdev symlinked to $target"
    fi

    # Check if target_dir is in PATH
    if [[ ":$PATH:" != *":$target_dir:"* ]]; then
        log_warning "$target_dir is not in your PATH"
        echo ""
        log_info "Add to your shell config (~/.zshrc or ~/.bashrc):"
        echo '  export PATH="$HOME/.local/bin:$PATH"'
        echo ""
        log_info "Then restart your shell or run:"
        echo '  export PATH="$HOME/.local/bin:$PATH"'
        echo ""
        log_info "Note: 'ctdev install zsh' configures this automatically"
    else
        log_success "ctdev is now available globally"
        log_info "Run 'ctdev --help' to get started"
    fi
}
