# Alias the vs-code "code" command to something shorter
# You can use it to open anything in vscode "c ." will open the current directory
alias c="code"

# Open your .zshrc in VS Code
alias zshrc="c ~/.zshrc"

# Restart the terminal and ZSH
alias restart="exec zsh"

alias cat="bat"
alias ls="exa"
# Show lots of info, even with icons!
alias lss="exa -alh --icons --git-ignore"

# Nodenv
eval "$(nodenv init -)"

export PATH=$HOME/.local/bin:$PATH
