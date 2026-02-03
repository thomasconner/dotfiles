#!/usr/bin/env bash

# ctdev info - Show system information

cmd_info() {
    local version
    version=$(get_version)

    echo
    log_step "System Information"
    echo

    # OS
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        # shellcheck disable=SC2153
        echo "  OS:              $NAME $VERSION"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  OS:              macOS $(sw_vers -productVersion)"
    else
        echo "  OS:              $(uname -s)"
    fi

    # Architecture
    echo "  Architecture:    $(uname -m)"

    # Package manager
    local pkg_manager
    pkg_manager=$(get_package_manager)
    echo "  Package Manager: $pkg_manager"

    # Shell
    echo "  Shell:           ${SHELL:-unknown}"

    # Dotfiles location
    echo "  Dotfiles:        $DOTFILES_ROOT"

    # ctdev version
    echo "  ctdev:           $version"

    echo
}
