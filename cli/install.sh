#!/usr/bin/env bash

set -euo pipefail

echo "CLI tools installation (jq, gh, kubectl, doctl, helm)"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

###
# jq (JSON processor)
###
if command -v jq >/dev/null 2>&1; then
  echo "jq is already installed: $(jq --version)"
else
  echo "Installing jq..."
  install_package jq
  echo "jq installed: $(jq --version)"
fi

###
# GitHub CLI (gh)
###
if command -v gh >/dev/null 2>&1; then
  echo "gh (GitHub CLI) is already installed: $(gh --version | head -n1)"
  echo "Checking for updates..."

  # Check if repository is configured
  if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
    echo "Adding gh repository for future updates..."
    ensure_curl_installed
    ensure_gpg_installed
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | maybe_sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | maybe_sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  fi

  maybe_sudo apt update
  maybe_sudo apt upgrade -y gh
  echo "gh is up to date: $(gh --version | head -n1)"
else
  echo "Installing gh (GitHub CLI)..."
  ensure_curl_installed
  ensure_gpg_installed

  # Add GitHub CLI repository
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | maybe_sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | maybe_sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

  maybe_sudo apt update
  maybe_sudo apt install -y gh

  echo "gh installed: $(gh --version | head -n1)"
fi

###
# kubectl (Kubernetes CLI)
###
ensure_curl_installed

# Get latest stable version
LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

if command -v kubectl >/dev/null 2>&1; then
  CURRENT_VERSION=$(kubectl version --client -o json 2>/dev/null | grep -oP '"gitVersion":\s*"\K[^"]+' || echo "unknown")
  echo "kubectl is installed: $CURRENT_VERSION"

  if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "Updating kubectl from $CURRENT_VERSION to $LATEST_VERSION..."

    TEMP_DIR=$(mktemp -d)
    register_cleanup_trap "$TEMP_DIR"
    cd "$TEMP_DIR"
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    maybe_sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    echo "kubectl updated: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
  else
    echo "kubectl is already up to date"
  fi
else
  echo "Installing kubectl ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"
  curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl"
  curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  maybe_sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

  echo "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

###
# doctl (DigitalOcean CLI)
###
ensure_curl_installed

# Get latest version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

if command -v doctl >/dev/null 2>&1; then
  CURRENT_VERSION=$(doctl version | grep -oP 'doctl version \K[0-9.]+')
  echo "doctl is installed: $CURRENT_VERSION"

  if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "Updating doctl from $CURRENT_VERSION to $LATEST_VERSION..."

    TEMP_DIR=$(mktemp -d)
    register_cleanup_trap "$TEMP_DIR"
    cd "$TEMP_DIR"
    curl -sL "https://github.com/digitalocean/doctl/releases/download/v${LATEST_VERSION}/doctl-${LATEST_VERSION}-linux-amd64.tar.gz" | tar -xz
    maybe_sudo install -o root -g root -m 0755 doctl /usr/local/bin/doctl

    echo "doctl updated: $(doctl version)"
  else
    echo "doctl is already up to date"
  fi
else
  echo "Installing doctl ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"
  curl -sL "https://github.com/digitalocean/doctl/releases/download/v${LATEST_VERSION}/doctl-${LATEST_VERSION}-linux-amd64.tar.gz" | tar -xz
  maybe_sudo install -o root -g root -m 0755 doctl /usr/local/bin/doctl

  echo "doctl installed: $(doctl version)"
fi

###
# helm (Kubernetes package manager)
###
ensure_curl_installed

# Get latest version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

if command -v helm >/dev/null 2>&1; then
  CURRENT_VERSION=$(helm version --short | grep -oP 'v\K[0-9.]+')
  echo "helm is installed: $CURRENT_VERSION"

  if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "Updating helm from $CURRENT_VERSION to $LATEST_VERSION..."

    TEMP_DIR=$(mktemp -d)
    register_cleanup_trap "$TEMP_DIR"
    cd "$TEMP_DIR"
    curl -fsSL "https://get.helm.sh/helm-v${LATEST_VERSION}-linux-amd64.tar.gz" -o helm.tar.gz
    tar -xzf helm.tar.gz
    maybe_sudo install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/helm

    echo "helm updated: $(helm version --short)"
  else
    echo "helm is already up to date"
  fi
else
  echo "Installing helm ${LATEST_VERSION}..."

  TEMP_DIR=$(mktemp -d)
  register_cleanup_trap "$TEMP_DIR"
  cd "$TEMP_DIR"
  curl -fsSL "https://get.helm.sh/helm-v${LATEST_VERSION}-linux-amd64.tar.gz" -o helm.tar.gz
  tar -xzf helm.tar.gz
  maybe_sudo install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/helm

  echo "helm installed: $(helm version --short)"
fi

echo "CLI tools installation complete!"
