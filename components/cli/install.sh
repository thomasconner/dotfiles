#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing CLI tools"

# Check for dry-run mode
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install the following CLI tools:"
    log_info "  - shellcheck"
    log_info "  - jq"
    log_info "  - gh (GitHub CLI)"
    log_info "  - kubectl"
    log_info "  - doctl (DigitalOcean CLI)"
    log_info "  - helm"
    log_info "  - age"
    log_info "  - sops"
    log_info "  - terraform"
    log_info "  - btop"
    log_info "  - docker"
    log_info "  - tmux"
    log_info "  - git-spice"
    log_success "CLI tools dry-run complete"
    exit 0
fi

# Install each CLI tool via its own script
"$SCRIPT_DIR/shellcheck.sh"
"$SCRIPT_DIR/jq.sh"
"$SCRIPT_DIR/gh.sh"
"$SCRIPT_DIR/kubectl.sh"
"$SCRIPT_DIR/doctl.sh"
"$SCRIPT_DIR/helm.sh"
"$SCRIPT_DIR/age.sh"
"$SCRIPT_DIR/sops.sh"
"$SCRIPT_DIR/terraform.sh"
"$SCRIPT_DIR/btop.sh"
"$SCRIPT_DIR/docker.sh"
"$SCRIPT_DIR/tmux/install.sh"
"$SCRIPT_DIR/git-spice.sh"

log_success "CLI tools installation complete"
