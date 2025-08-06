# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Path configuration ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# setopt extended_glob null_glob

path=(
  $path
  $HOME/bin
  $HOME/.local/bin
  $HOME/.nodenv/bin
  $SCRIPTS
)

# Remove duplicate entries and non-existent directories
typeset -U path
path=($^path(N-/))

export path

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SSH ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# setup to use GPG + YubiKey for ssh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Environment Variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Directories

export REPOS="$HOME/Repos"
export GITUSER="thomasconner"
export GHREPOS="$REPOS/github.com"
export DOTFILES="$GHREPOS/$GITUSER/dotfiles"
export SCRIPTS="$DOTFILES/scripts"

# Go related. In general all executables and scripts go in .local/bin

export GOBIN="$HOME/.local/bin"
# export GOPATH="$HOME/go/"

# AWS CLI

export AWS_PROFILE=developer-access-767828768904

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ History ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_SPACE  # Don't save when prefixed with space
setopt HIST_IGNORE_DUPS   # Don't save duplicate lines
setopt SHARE_HISTORY      # Share history between sessions


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Oh My Zsh ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  common-aliases
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PURE_GIT_PULL=0

fpath+=($HOME/.zsh/pure)

autoload -U promptinit; promptinit
prompt pure

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Completion ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

fpath+=($HOME/.zfunc)
fpath+=($HOME/.nodenv/completions)

autoload -Uz compinit
compinit -u

zstyle ':completion:*' menu select

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Aliases ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# alias scripts='cd $SCRIPTS'

# Repos

alias repos='cd $REPOS'
alias ghrepos='cd $GHREPOS'
alias bwarepos='cd $GHREPOS/BlueWaterAutonomy'
alias ctrepos='cd $GHREPOS/ConnerTechnology'
alias 6rsrepos='cd $GHREPOS/6RiverSystems'

# ls

alias ls='ls --color=auto'
alias la='ls -laXh'

# finds all files recursively and sorts by last modification, ignore hidden files
# alias lastmod='find . -type f -not -path "*/\.*" -exec ls -lrt {} +'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ NODENV ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

eval "$(nodenv init -)"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Misc ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
