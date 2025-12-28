#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# Skip system package updates - devcontainers manage packages via Dockerfile
# and typically have "no new privileges" flag that blocks sudo
exec ./ctdev install --skip-system zsh
