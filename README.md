# dotfiles

### Instructions
1. `git clone https://github.com/AdamVig/dotfiles.git`
2. `./bin/,bootstrap`
3. enter your password

*Note:* moving the `dotfiles` folder requires re-running `,bootstrap` to re-establish the symlinks to your home directory.

After cloning, run the following command to configure the repository's Git hooks:
```shell
git config --local core.hooksPath scripts/git-hooks
```

### File Structure
#### `.vscode/`
Settings, keybindings, and snippets for Visual Studio Code.  
#### `bin/`
Various scripts, including `bootstrap`.
#### `.aliases`
Abbreviations for common commands.  
#### `.bash_profile`  
Loads all other files. Executed for login shells.  
#### `.bashrc`  
Loads `.bash_profile`, which loads all other files. Executed for interactive non-login shells.  
#### `.exports`  
Environment variables.  
#### `.zshrc`  
Configure Zsh. Loads `.bash_profile` in case it has not already been loaded.  

For machine-specific environment variables or shell configuration, create `~/.locals`. This file will be sourced by `.bash_profile`.
