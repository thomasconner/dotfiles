#!/usr/bin/env bash

# ctdev list - List available components with status

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GREY='\033[0;90m'
NC='\033[0m' # No Color

cmd_list() {
    echo
    log_step "Components"
    echo

    local name desc _script
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r name desc _script <<< "$component"

        local status_text status_color

        if is_component_installed "$name"; then
            # Check if updates available (for components that support it)
            if has_updates_available "$name"; then
                status_text="installed (update available)"
                status_color="$YELLOW"
            else
                status_text="installed"
                status_color="$GREEN"
            fi
        else
            status_text="not installed"
            status_color="$GREY"
        fi

        printf "  %-20s ${status_color}%s${NC}\n" "$name" "$status_text"
    done

    echo
}

# Check if a component has updates available
# Returns 0 if updates available, 1 otherwise
has_updates_available() {
    local component="$1"

    case "$component" in
        zsh)
            # Check if any zsh-related git repos are behind
            for repo in "$HOME/.oh-my-zsh" "$HOME/.zsh/pure"; do
                if [[ -d "$repo/.git" ]]; then
                    local behind
                    behind=$(git -C "$repo" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || continue
                    if [[ "$behind" -gt 0 ]]; then
                        return 0
                    fi
                fi
            done
            ;;
        node)
            if [[ -d "$HOME/.nodenv/.git" ]]; then
                local behind
                behind=$(git -C "$HOME/.nodenv" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || return 1
                if [[ "$behind" -gt 0 ]]; then
                    return 0
                fi
            fi
            ;;
        ruby)
            if [[ -d "$HOME/.rbenv/.git" ]]; then
                local behind
                behind=$(git -C "$HOME/.rbenv" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || return 1
                if [[ "$behind" -gt 0 ]]; then
                    return 0
                fi
            fi
            ;;
    esac

    return 1
}
