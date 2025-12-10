#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo " Testing ctdev CLI"
echo "=========================================="
echo ""

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

test_passed=0
test_failed=0

# Helper function to run tests
run_test() {
  local test_name="$1"
  local command="$2"

  echo -n "Testing: $test_name ... "

  if eval "$command" > /dev/null 2>&1; then
    echo -e "${GREEN}PASSED${NC}"
    ((test_passed++))
    return 0
  else
    echo -e "${RED}FAILED${NC}"
    ((test_failed++))
    return 1
  fi
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}==> Testing CLI commands${NC}"
echo ""

run_test "ctdev --help" "$SCRIPT_DIR/ctdev --help"
run_test "ctdev --version" "$SCRIPT_DIR/ctdev --version"
run_test "ctdev list" "$SCRIPT_DIR/ctdev list"
run_test "ctdev doctor" "$SCRIPT_DIR/ctdev doctor"
run_test "ctdev info" "$SCRIPT_DIR/ctdev info"
run_test "ctdev --dry-run install" "$SCRIPT_DIR/ctdev --dry-run install"

echo ""
echo -e "${BLUE}==> Testing syntax of all scripts${NC}"
echo ""

# Check all shell scripts for syntax errors
syntax_errors=0
while IFS= read -r -d '' file; do
  if ! bash -n "$file" 2>/dev/null; then
    echo -e "${RED}Syntax error in: $file${NC}"
    ((syntax_errors++))
  fi
done < <(find "$SCRIPT_DIR" -name "*.sh" -type f -print0)

# Check ctdev main script
if ! bash -n "$SCRIPT_DIR/ctdev" 2>/dev/null; then
  echo -e "${RED}Syntax error in: ctdev${NC}"
  ((syntax_errors++))
fi

if [ $syntax_errors -eq 0 ]; then
  echo -e "${GREEN}All scripts have valid syntax${NC}"
  ((test_passed++))
else
  echo -e "${RED}Found $syntax_errors scripts with syntax errors${NC}"
  ((test_failed++))
fi

# Test Docker if available
if command -v docker >/dev/null 2>&1; then
  echo ""
  echo -e "${BLUE}==> Testing Ubuntu container installation${NC}"
  echo ""

  for version in "22.04" "24.04"; do
    echo "Testing Ubuntu $version..."

    if docker run --rm -v "$SCRIPT_DIR:/dotfiles" "ubuntu:$version" bash -c "
      set -euo pipefail
      cd /dotfiles
      apt-get update -qq
      apt-get install -y -qq git sudo curl >/dev/null 2>&1

      # Test CLI
      ./ctdev --version
      ./ctdev list
      ./ctdev doctor

      # Install zsh
      ./ctdev install zsh

      # Verify
      command -v zsh >/dev/null || exit 1
      [ -d ~/.oh-my-zsh ] || exit 1
      [ -d ~/.zsh/pure ] || exit 1
      [ -f ~/.zshrc ] || exit 1

      echo 'All checks passed!'
    " 2>&1; then
      echo -e "${GREEN}Ubuntu $version test PASSED${NC}"
      ((test_passed++))
    else
      echo -e "${RED}Ubuntu $version test FAILED${NC}"
      ((test_failed++))
    fi
  done
else
  echo ""
  echo -e "${BLUE}[SKIP] Docker not available, skipping container tests${NC}"
fi

echo ""
echo "=========================================="
echo " Test Results"
echo "=========================================="
echo -e "Passed: ${GREEN}$test_passed${NC}"
echo -e "Failed: ${RED}$test_failed${NC}"
echo ""

if [ $test_failed -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
