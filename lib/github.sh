#!/usr/bin/env bash

# GitHub and Git repository functions for ctdev CLI
# Part of the Conner Technology dotfiles

###############################################################################
# GitHub Release Functions
###############################################################################

# Fetch the latest release version from a GitHub repository
# Uses jq if available, falls back to grep/sed
# Usage: github_latest_version "owner/repo"
# Returns: version string (without 'v' prefix)
github_latest_version() {
  local repo="$1"
  local version=""
  local api_url="https://api.github.com/repos/${repo}/releases/latest"

  ensure_curl_installed

  local response
  response=$(curl -fsSL "$api_url" 2>/dev/null) || {
    log_error "Failed to fetch release info from GitHub for $repo"
    return 1
  }

  if command -v jq >/dev/null 2>&1; then
    version=$(echo "$response" | jq -r '.tag_name // empty' 2>/dev/null)
  else
    version=$(echo "$response" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  fi

  if [[ -z "$version" ]]; then
    log_error "Could not parse version from GitHub API response for $repo"
    return 1
  fi

  # Remove 'v' prefix if present
  echo "${version#v}"
}

###############################################################################
# Checksum Verification Functions
###############################################################################

# Verify SHA256 checksum of a file
# Usage: verify_sha256 "file_path" "expected_checksum"
# Returns: 0 on success, 1 on failure
verify_sha256() {
  local file="$1"
  local expected="$2"

  if [[ ! -f "$file" ]]; then
    log_error "File not found for checksum verification: $file"
    return 1
  fi

  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$file" | cut -d' ' -f1)
  elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
  else
    log_error "No SHA256 tool available (need sha256sum or shasum)"
    return 1
  fi

  if [[ "$actual" != "$expected" ]]; then
    log_error "Checksum verification failed for $file"
    log_error "  Expected: $expected"
    log_error "  Actual:   $actual"
    return 1
  fi

  log_debug "Checksum verified for $file"
  return 0
}

# Verify checksum from a checksums file (common format: "hash  filename")
# Usage: verify_checksum_file "file_to_verify" "checksums_file"
# Returns: 0 on success, 1 on failure
verify_checksum_from_file() {
  local file="$1"
  local checksums_file="$2"
  local filename
  filename=$(basename "$file")

  if [[ ! -f "$checksums_file" ]]; then
    log_error "Checksums file not found: $checksums_file"
    return 1
  fi

  # Extract the expected checksum for this file
  local expected
  expected=$(grep -E "(^| )${filename}$" "$checksums_file" | head -1 | awk '{print $1}')

  if [[ -z "$expected" ]]; then
    log_error "Could not find checksum for $filename in $checksums_file"
    return 1
  fi

  verify_sha256 "$file" "$expected"
}

###############################################################################
# Git Repository Functions
###############################################################################

# Pull latest changes from a git repository, trying common default branches
# Usage: git_pull_default_branch "/path/to/repo" "repo-name"
# Returns: 0 on success, 1 on failure
git_pull_default_branch() {
  local repo_dir="$1"
  local repo_name="${2:-$(basename "$repo_dir")}"

  if [[ ! -d "$repo_dir/.git" ]]; then
    log_warning "$repo_name is not a git repository"
    return 1
  fi

  # In devcontainers, disable URL rewrites to avoid SSH issues
  local git_cmd="git"
  if is_devcontainer; then
    git_cmd="git -c url.https://github.com/.insteadOf=git@github.com: -c url.https://github.com/.insteadOf=ssh://git@github.com/"
  fi

  # Try common default branches in order of popularity
  for branch in main master; do
    if $git_cmd -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
      if $git_cmd -C "$repo_dir" pull --ff-only origin "$branch" 2>/dev/null; then
        log_debug "Updated $repo_name from origin/$branch"
        return 0
      fi
    fi
  done

  # Fallback: try pulling without specifying a branch
  if $git_cmd -C "$repo_dir" pull --ff-only 2>/dev/null; then
    log_debug "Updated $repo_name"
    return 0
  fi

  log_warning "Could not update $repo_name"
  return 1
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
      run_cmd git -C "$target_dir" pull --ff-only
    else
      echo "Directory $target_dir exists but is not a git repository"
      return 1
    fi
  else
    printf "Cloning %s to %s\n" "$repo_name" "$target_dir"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_info "[DRY-RUN] Would clone $repo_url to $target_dir"
    else
      # In devcontainers, disable URL rewrites to avoid SSH issues with public repos
      if is_devcontainer; then
        git -c url."https://github.com/".insteadOf="git@github.com:" \
            -c url."https://github.com/".insteadOf="ssh://git@github.com/" \
            clone "$repo_url" "$target_dir"
      else
        git clone "$repo_url" "$target_dir"
      fi
    fi
  fi
}
