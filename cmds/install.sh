#!/usr/bin/env bash

# ctdev install - Install dotfiles components

cmd_install() {
    local components=()

    # Parse subcommand arguments, filtering out flags that were already processed
    for arg in "$@"; do
        case "$arg" in
            -h|--help|-v|--verbose|-n|--dry-run)
                # Already handled by main dispatcher
                ;;
            *)
                components+=("$arg")
                ;;
        esac
    done

    # If no components specified, install all in default order
    if [[ ${#components[@]} -eq 0 ]]; then
        # shellcheck disable=SC2206
        components=($DEFAULT_INSTALL_ORDER)
        log_step "Installing all components"
    else
        # Validate specified components
        if ! validate_components "${components[@]}"; then
            return 1
        fi
        log_step "Installing selected components: ${components[*]}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    local failed=()
    local succeeded=()

    for component in "${components[@]}"; do
        local script
        script=$(get_component_install_script "$component")

        if [[ ! -f "$script" ]]; then
            log_warning "Install script not found for $component: $script"
            failed+=("$component")
            continue
        fi

        log_step "Installing $component"

        # Run the install script, passing through environment (including DRY_RUN)
        # Scripts handle their own dry-run logic
        if bash "$script"; then
            succeeded+=("$component")
            # Create installation marker for tracking
            create_install_marker "$component"
        else
            log_error "Failed to install $component"
            failed+=("$component")
        fi

        echo ""
    done

    # Summary
    log_step "Installation complete"

    if [[ ${#succeeded[@]} -gt 0 ]]; then
        log_success "Installed: ${succeeded[*]}"
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed: ${failed[*]}"
        return 1
    fi

    return 0
}
