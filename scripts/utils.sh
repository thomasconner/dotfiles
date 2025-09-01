#!/usr/bin/env bash

# Shared utility functions for dotfiles installation scripts

# Ensure git is installed
ensure_git_installed() {
  if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed. Installing..."
    sudo apt update
    sudo apt install -y git
    echo "git installed successfully"
  fi
}

# Ensure curl is installed
ensure_curl_installed() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is not installed. Installing..."
    sudo apt update
    sudo apt install -y curl
    echo "curl installed successfully"
  fi
}

# Ensure wget is installed
ensure_wget_installed() {
  if ! command -v wget >/dev/null 2>&1; then
    echo "wget is not installed. Installing..."
    sudo apt update
    sudo apt install -y wget
    echo "wget installed successfully"
  fi
}

ensure_gpg_installed() {
  if ! command -v gpg >/dev/null 2>&1; then
    echo "gpg is not installed. Installing..."
    sudo apt update
    sudo apt install -y gpg
    echo "gpg installed successfully"
  fi
}

# Check if a directory exists and is a git repository, then pull or clone
ensure_git_repo() {
  local repo_url="$1"
  local target_dir="$2"
  local repo_name="${repo_url##*/}"
  repo_name="${repo_name%.git}"

  if [ -z "$repo_url" ] || [ -z "$target_dir" ]; then
    echo "Usage: ensure_git_repo <repo_url> <target_dir>"
    return 1
  fi

  ensure_git_installed

  if [ -d "$target_dir" ]; then
    if [ -d "$target_dir/.git" ]; then
      printf "%s is already installed, updating\n" "$repo_name"
      git -C "$target_dir" pull --ff-only
    else
      echo "Directory $target_dir exists but is not a git repository"
      return 1
    fi
  else
    printf "Cloning %s to %s\n" "$repo_name" "$target_dir"
    git clone "$repo_url" "$target_dir"
  fi
}
