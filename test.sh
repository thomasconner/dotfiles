#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo " Testing Dotfiles Installation"
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

# Test Docker availability
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Error: Docker is not installed${NC}"
  exit 1
fi

echo -e "${BLUE}==> Testing Ubuntu 22.04 (containers.sh)${NC}"
echo ""

# Test minimal installation
docker run --rm -v "$PWD:/dotfiles" ubuntu:22.04 bash -c "
  set -euo pipefail
  cd /dotfiles

  # Run actual installation
  echo '==> Running installation...'
  ./containers.sh

  # Verify installations
  echo '==> Verifying installations...'
  command -v git >/dev/null || exit 1
  command -v zsh >/dev/null || exit 1
  command -v gh >/dev/null || exit 1
  command -v kubectl >/dev/null || exit 1
  command -v doctl >/dev/null || exit 1

  # Verify config files
  [ -f ~/.gitconfig ] || exit 1
  [ -f ~/.zshrc ] || exit 1

  echo '==> All checks passed!'
"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Ubuntu 22.04 test PASSED${NC}"
  ((test_passed++))
else
  echo -e "${RED}✗ Ubuntu 22.04 test FAILED${NC}"
  ((test_failed++))
fi

echo ""
echo -e "${BLUE}==> Testing Ubuntu 24.04 (containers.sh)${NC}"
echo ""

docker run --rm -v "$PWD:/dotfiles" ubuntu:24.04 bash -c "
  set -euo pipefail
  cd /dotfiles

  # Run installation
  echo '==> Running installation...'
  ./containers.sh

  # Verify installations
  echo '==> Verifying installations...'
  command -v git >/dev/null || exit 1
  command -v zsh >/dev/null || exit 1
  command -v gh >/dev/null || exit 1

  echo '==> All checks passed!'
"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Ubuntu 24.04 test PASSED${NC}"
  ((test_passed++))
else
  echo -e "${RED}✗ Ubuntu 24.04 test FAILED${NC}"
  ((test_failed++))
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
