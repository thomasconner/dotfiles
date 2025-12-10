# Path

# User binaries first (for ctdev and other user-installed tools)
path=(
  $HOME/.local/bin
  $HOME/bin
  $path
)

# Homebrew paths (macOS)
# Apple Silicon Macs use /opt/homebrew, Intel Macs use /usr/local
if [[ -d "/opt/homebrew" ]]; then
  # Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true
elif [[ -d "/usr/local/Homebrew" ]]; then
  # Intel Mac
  eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || true
fi

path=(
  $path
  /usr/local/bin
  /usr/local/sbin
  $HOME/.nodenv/bin
  $HOME/.rbenv/bin
  $GOPATH/bin
  $GOROOT/bin
)

# Remove duplicate entries and non-existent directories
typeset -U path
path=($^path(N-/))

export path
