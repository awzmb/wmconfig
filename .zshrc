### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

### custom configuration
# vi bindings
bindkey -v

# modules (turbo mode)
zinit ice wait'!0'
#zinit light marlonrichert/zsh-autocomplete

# colorizes various shell tools (grep, diff, ip, ...)
# NOTE: currently disabled because alpine busybox does not support certain grep options
#zinit light zpm-zsh/colorize
#
# change login terminal colors
if [ "$TERM" = "linux" ]; then
    echo -en "\e]P0242933" #black
    echo -en "\e]P83B4252" #darkgrey
    echo -en "\e]P1BF616A" #darkred
    echo -en "\e]P9BF616A" #red
    echo -en "\e]P2A3BE8C" #darkgreen
    echo -en "\e]PAA3BE8C" #green
    echo -en "\e]P3EBCB8B" #brown
    echo -en "\e]PBEBCB8B" #yellow
    echo -en "\e]P481A1C1" #darkblue
    echo -en "\e]PC81A1C1" #blue
    echo -en "\e]P5B48EAD" #darkmagenta
    echo -en "\e]PDB48EAD" #magenta
    echo -en "\e]P688C0D0" #darkcyan
    echo -en "\e]PE88C0D0" #cyan
    echo -en "\e]P7E5E9F0" #lightgrey
    echo -en "\e]PFD8DEE9" #white
    #clear #for background artifacting
fi

# aliases
source ~/.aliases

# add script and appimage to path
export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.appimage:$PATH"
export PATH="$HOME/.bin:$PATH"

# add snap to path on linux
if [ "$(uname)" = "Linux" ]; then
  export PATH="/snap/bin:$PATH"
fi

# add golaang path
export GOPATH="$HOME/go"
export GOROOT="${HOME}/.go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$GOROOT/bin"

# source theme
source ~/.zsh/theme.zsh

# completion settings
source ~/.zsh/completion-settings.zsh

# change ls colors to match system
source ~/.zsh/completion-colors.zsh

# general settings
source ~/.zsh/general-settings.zsh

# rationalize dot
source ~/.zsh/rationalize-dot.zsh

# vi mode settings
source ~/.zsh/vi-mode.zsh

# tab completion generator
source ~/.zsh/completion-generator.zsh

# fzf integration
source ~/.zsh/fzf-settings.zsh
source ~/.zsh/fzf-completion.zsh
source ~/.zsh/fzf-keybindings.zsh

# fzf tab completion
source ~/.zsh/fzf-tab-completion.zsh

# several fixes for different systems
source ~/.zsh/fixes.zsh

# additional tools
source ~/.zsh/tools.zsh

# asdf completion
#if [ "$(uname)" = "Darwin" ]; then
#  source "$( brew --prefix asdf )/asdf.sh"
#fi

# asdf terragrunt terraform version fix
#if [ "$(uname)" = "Darwin" ]; then
#  export TERRAGRUNT_TFPATH=$(asdf which terraform)
#fi

# fix for zscaler if .certificates exists in home
if [ -d "$HOME/.certificates" ]; then
  export AWS_CA_BUNDLE=$HOME/.certificates/Certificates.pem
fi

# additional stuff
if [ "$(uname)" = "Linux" ]; then
  # dont use gui to enter git credentials
  unset SSH_ASKPASS
  # keyboard layout
  #setxkbmap us -variant altgr-intl
  # use caps as escape button
  #setxkbmap -option caps:escape
  export XDG_RUNTIME_DIR=$HOME/.tmp
fi

# trigger completion initialization
compinit

# krew kubectl plugin manager
export PATH="${PATH}:${HOME}/.krew/bin"

# kubectl completion
source <(kubectl completion zsh)

# openjdk 11
export PATH="${PATH}:${HOME}/.jdk/openjdk-11/bin"
export JAVA_HOME="${HOME}/.jdk/openjdk-11"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=$PATH:/home/awzm/.spicetify
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# add pip local cache to path
export PATH="${PATH}:${HOME}/.local/bin"

# add brew to env if installed
if [[ -d "/home/linuxbrew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

command -v flux >/dev/null && . <(flux completion zsh)
command -v helm >/dev/null && . <(helm completion zsh)

# spicetify
export PATH=$PATH:/home/bawzm/.spicetify
