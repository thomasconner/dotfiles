#!/usr/bin/env bash

set -euo pipefail

# Get script directory for version file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "dev")

###
# Parse command line arguments
###
DRY_RUN=false
VERBOSE=false

show_help() {
  cat << EOF
Dotfiles Installer v${VERSION}

Usage: $0 [OPTIONS]

Install dotfiles for desktop environment (full installation).

OPTIONS:
  -n, --dry-run     Show what would be done without making changes
  -v, --verbose     Enable verbose output
  --version         Show version information
  -h, --help        Show this help message

EXAMPLES:
  $0                # Normal installation
  $0 --dry-run      # Preview changes without installing
  $0 --verbose      # Show detailed output

EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run|-n)
      DRY_RUN=true
      export DRY_RUN
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      export VERBOSE
      set -x  # Enable bash debugging
      shift
      ;;
    --version)
      echo "Dotfiles v${VERSION}"
      exit 0
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

echo "Dotfiles Installer v${VERSION}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "======================================"
  echo " DRY RUN MODE - No changes will be made"
  echo "======================================"
  echo ""
fi

###
# Installation
###
"${SCRIPT_DIR}/apps/install.sh"
"${SCRIPT_DIR}/cli/install.sh"
"${SCRIPT_DIR}/fonts/install.sh"
"${SCRIPT_DIR}/git/install.sh"
"${SCRIPT_DIR}/node/install.sh"
"${SCRIPT_DIR}/ruby/install.sh"
"${SCRIPT_DIR}/zsh/install.sh"

###
# Manual notifications
###
echo "🚀 Manual installation/updates"
echo "Omz: omz update"
echo ""
