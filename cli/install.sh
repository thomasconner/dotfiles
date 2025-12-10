#!/usr/bin/env bash

set -euo pipefail

echo "CLI tools installation (jq, gh, kubectl, doctl, helm, age, sops, terraform, docker)"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/utils.sh"

# Detect OS and architecture
OS=$(detect_os)
ARCH=$(detect_arch)

log_info "Detected OS: $OS, Architecture: $ARCH"

###############################################################################
# macOS Installation (via Homebrew)
###############################################################################

install_cli_tools_macos() {
  log_step "Installing CLI tools via Homebrew"

  ensure_brew_installed

  # List of CLI tools to install via brew
  local tools=(jq gh kubectl doctl helm age sops terraform)

  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      log_info "$tool is already installed: $(get_tool_version "$tool")"
    else
      log_info "Installing $tool..."
      brew install "$tool"
      log_success "$tool installed: $(get_tool_version "$tool")"
    fi
  done

  log_success "CLI tools installation complete (macOS)"
}

# Get version string for a tool (handles different version flags)
get_tool_version() {
  local tool="$1"
  case "$tool" in
    kubectl)
      kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -n1
      ;;
    doctl)
      doctl version 2>/dev/null | head -n1
      ;;
    helm)
      helm version --short 2>/dev/null || helm version 2>/dev/null | head -n1
      ;;
    age)
      age --version 2>&1 | head -n1
      ;;
    sops)
      sops --version 2>&1 | head -n1
      ;;
    terraform)
      terraform version 2>/dev/null | head -n1
      ;;
    *)
      $tool --version 2>&1 | head -n1
      ;;
  esac
}

###############################################################################
# Linux Installation (via apt/direct download)
###############################################################################

install_cli_tools_linux() {
  log_step "Installing CLI tools for Linux"

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

      # Use Ubuntu base codename for derivatives (e.g., Linux Mint)
      CODENAME=$(lsb_release -cs)
      if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [ -n "${UBUNTU_CODENAME:-}" ]; then
          CODENAME="$UBUNTU_CODENAME"
        fi
      fi

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

    # Use Ubuntu base codename for derivatives (e.g., Linux Mint)
    CODENAME=$(lsb_release -cs)
    if [ -f /etc/os-release ]; then
      source /etc/os-release
      if [ -n "${UBUNTU_CODENAME:-}" ]; then
        CODENAME="$UBUNTU_CODENAME"
      fi
    fi

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
      curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl"
      curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl.sha256"
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
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl"
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl.sha256"
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
      curl -sL "https://github.com/digitalocean/doctl/releases/download/v${LATEST_VERSION}/doctl-${LATEST_VERSION}-linux-${ARCH}.tar.gz" | tar -xz
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
    curl -sL "https://github.com/digitalocean/doctl/releases/download/v${LATEST_VERSION}/doctl-${LATEST_VERSION}-linux-${ARCH}.tar.gz" | tar -xz
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
      curl -fsSL "https://get.helm.sh/helm-v${LATEST_VERSION}-linux-${ARCH}.tar.gz" -o helm.tar.gz
      tar -xzf helm.tar.gz
      maybe_sudo install -o root -g root -m 0755 "linux-${ARCH}/helm" /usr/local/bin/helm

      echo "helm updated: $(helm version --short)"
    else
      echo "helm is already up to date"
    fi
  else
    echo "Installing helm ${LATEST_VERSION}..."

    TEMP_DIR=$(mktemp -d)
    register_cleanup_trap "$TEMP_DIR"
    cd "$TEMP_DIR"
    curl -fsSL "https://get.helm.sh/helm-v${LATEST_VERSION}-linux-${ARCH}.tar.gz" -o helm.tar.gz
    tar -xzf helm.tar.gz
    maybe_sudo install -o root -g root -m 0755 "linux-${ARCH}/helm" /usr/local/bin/helm

    echo "helm installed: $(helm version --short)"
  fi

  ###
  # age (file encryption tool)
  ###
  ensure_curl_installed

  # Get latest version from GitHub
  LATEST_VERSION=$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

  if command -v age >/dev/null 2>&1; then
    CURRENT_VERSION=$(age --version 2>&1 | grep -oP 'v\K[0-9.]+' || echo "unknown")
    echo "age is installed: $CURRENT_VERSION"

    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
      echo "Updating age from $CURRENT_VERSION to $LATEST_VERSION..."

      TEMP_DIR=$(mktemp -d)
      register_cleanup_trap "$TEMP_DIR"
      cd "$TEMP_DIR"
      curl -sL "https://github.com/FiloSottile/age/releases/download/v${LATEST_VERSION}/age-v${LATEST_VERSION}-linux-${ARCH}.tar.gz" | tar -xz
      maybe_sudo install -o root -g root -m 0755 age/age /usr/local/bin/age
      maybe_sudo install -o root -g root -m 0755 age/age-keygen /usr/local/bin/age-keygen

      echo "age updated: $(age --version 2>&1 | head -n1)"
    else
      echo "age is already up to date"
    fi
  else
    echo "Installing age ${LATEST_VERSION}..."

    TEMP_DIR=$(mktemp -d)
    register_cleanup_trap "$TEMP_DIR"
    cd "$TEMP_DIR"
    curl -sL "https://github.com/FiloSottile/age/releases/download/v${LATEST_VERSION}/age-v${LATEST_VERSION}-linux-${ARCH}.tar.gz" | tar -xz
    maybe_sudo install -o root -g root -m 0755 age/age /usr/local/bin/age
    maybe_sudo install -o root -g root -m 0755 age/age-keygen /usr/local/bin/age-keygen

    echo "age installed: $(age --version 2>&1 | head -n1)"
  fi

  ###
  # sops (secrets management)
  ###
  ensure_curl_installed

  # Get latest version from GitHub
  LATEST_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

  if command -v sops >/dev/null 2>&1; then
    CURRENT_VERSION=$(sops --version 2>&1 | grep -oP 'sops \K[0-9.]+')
    echo "sops is installed: $CURRENT_VERSION"

    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
      echo "Updating sops from $CURRENT_VERSION to $LATEST_VERSION..."

      TEMP_DIR=$(mktemp -d)
      register_cleanup_trap "$TEMP_DIR"
      cd "$TEMP_DIR"
      curl -sL "https://github.com/getsops/sops/releases/download/v${LATEST_VERSION}/sops-v${LATEST_VERSION}.linux.${ARCH}" -o sops
      maybe_sudo install -o root -g root -m 0755 sops /usr/local/bin/sops

      echo "sops updated: $(sops --version 2>&1)"
    else
      echo "sops is already up to date"
    fi
  else
    echo "Installing sops ${LATEST_VERSION}..."

    TEMP_DIR=$(mktemp -d)
    register_cleanup_trap "$TEMP_DIR"
    cd "$TEMP_DIR"
    curl -sL "https://github.com/getsops/sops/releases/download/v${LATEST_VERSION}/sops-v${LATEST_VERSION}.linux.${ARCH}" -o sops
    maybe_sudo install -o root -g root -m 0755 sops /usr/local/bin/sops

    echo "sops installed: $(sops --version 2>&1)"
  fi

  ###
  # terraform (infrastructure as code)
  ###
  ensure_curl_installed
  ensure_gpg_installed

  if command -v terraform >/dev/null 2>&1; then
    CURRENT_VERSION=$(terraform version -json 2>/dev/null | grep -oP '"terraform_version":\s*"\K[^"]+' || terraform version | grep -oP 'Terraform v\K[0-9.]+')
    echo "terraform is installed: $CURRENT_VERSION"
    echo "Run 'sudo apt update && sudo apt upgrade terraform' to update terraform"
  else
    echo "Installing terraform..."

    # Use Ubuntu base codename for derivatives (e.g., Linux Mint)
    CODENAME=$(lsb_release -cs)
    if [ -f /etc/os-release ]; then
      source /etc/os-release
      if [ -n "${UBUNTU_CODENAME:-}" ]; then
        CODENAME="$UBUNTU_CODENAME"
      fi
    fi

    # Add HashiCorp GPG key and repository
    curl -fsSL https://apt.releases.hashicorp.com/gpg | maybe_sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $CODENAME main" | maybe_sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

    maybe_sudo apt update
    maybe_sudo apt install -y terraform

    echo "terraform installed: $(terraform version | head -n1)"
  fi

  log_success "CLI tools installation complete (Linux)"
}

###############################################################################
# Main
###############################################################################

if [[ "$OS" == "macos" ]]; then
  install_cli_tools_macos
else
  install_cli_tools_linux
fi

# Install Docker (separate script handles macOS vs Linux differences)
"$SCRIPT_DIR/docker.sh"

echo "CLI tools installation complete!"
