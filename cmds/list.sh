#!/usr/bin/env bash

# ctdev list - List available components

cmd_list() {
    local show_installed_only=false

    # Parse subcommand flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --installed)
                show_installed_only=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    log_step "Available Components"
    echo

    local name desc script status
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r name desc script <<< "$component"

        if is_component_installed "$name"; then
            status="installed"
        else
            status="not installed"
        fi

        # Skip non-installed if --installed flag is set
        if [[ "$show_installed_only" == "true" ]] && [[ "$status" != "installed" ]]; then
            continue
        fi

        if [[ "$status" == "installed" ]]; then
            log_success "$name"
        else
            echo "  $name"
        fi
        echo "      $desc"
        echo "      Status: $status"
        echo
    done
}
