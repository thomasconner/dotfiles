#!/usr/bin/env bash

# ctdev update - DEPRECATED: use 'ctdev upgrade' instead

cmd_update() {
    log_warning "'ctdev update' is deprecated. Use 'ctdev upgrade --check' instead."
    log_warning "For key refresh, use 'ctdev upgrade --refresh-keys'."
    echo

    # Forward to upgrade --check, passing through any extra args
    cmd_upgrade --check "$@"
}
