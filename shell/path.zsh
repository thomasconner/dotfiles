# Path
path=(
  $path
  /usr/local/bin
  $HOME/bin
  $HOME/.local/bin
  $HOME/.nodenv/bin
  $GOPATH/bin
  $GOROOT/bin
)

# Remove duplicate entries and non-existent directories
typeset -U path
path=($^path(N-/))

export path
