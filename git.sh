#!/usr/bin/env bash

DIR="$(dirname "$(realpath "$0")")"

# shellcheck source=./helpers.sh
source "$DIR"/helpers.sh

message "setting up Git..."

config_path="$XDG_CONFIG_HOME/git"

if [ -e "$HOME"/.gitconfig ]; then
  message "Migrating to new configuration file location..."
  mkdir -p "$config_path"
  mv "$HOME"/.gitconfig "$config_path"/config
fi

# If gitconfig does not exist already, create one
if ! [ -e "$config_path"/config ]; then
    message "  %s" "copying gitconfig to '$config_path/config'..."
    cp "$DIR"/.gitconfig "$config_path"/config
    
    message "  %s" "configuring Git user..."
    read -r -p "  Full name: " name
    read -r -p "  Email address: " email
    read -r -p "  GitHub username: " github

    # Only set values if they are non-empty
    [ -n "$name" ] && git config --global user.name "$name"
    [ -n "$email" ] && git config --global user.email "$email"
    [ -n "$github" ] && git config --global github.user "$github"
    message "  %s" "done configuring Git user"

    if "$DIR"/bin/is-wsl; then
      message "  %s" "setting credential helper for WSL..."
      git config --global credential.helper \
        '/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe'
    fi
else
  message "  %s" "updating Git configuration..."
  # Read all values from current Git configuration
  git config --list --file "$DIR"/.gitconfig | while read -r conf_line; do
    # Split line into name and value at equals sign
    IFS='=' read -r -a name_value <<< "$conf_line"
    name="${name_value[0]}"
    value="${name_value[1]}"

    # If this configuration key is not already set, set it
    if ! git config "$name" &> /dev/null; then
      message "    %s" "setting '$name'..."
      git config "$name" "$value"
    fi
  done
  message "  %s" "done updating Git configuration"
fi

message "done setting up Git"
