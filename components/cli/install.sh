#!/usr/bin/env bash

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/lib/utils.sh"

log_step "Installing CLI tools"

# Install each CLI tool via its own script
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

log_success "CLI tools installation complete"
