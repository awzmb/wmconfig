### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
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

# aliases
source ~/.aliases

# add script folder to path
export PATH="$HOME/.scripts:$PATH"

# add golaang path
export GOPATH="$HOME/go"
export GOROOT="/usr/local/opt/go/libexec"
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
fi

# trigger completion initialization
compinit
