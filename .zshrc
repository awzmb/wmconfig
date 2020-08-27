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
zinit light zdharma/fast-syntax-highlighting
zinit light zpm-zsh/colorize

# aliases
source ~/.aliases

# add script folder to path
export PATH="~/.scripts:$PATH"

# source theme
source ~/.zsh/theme.zsh

# general settings
source ~/.zsh/general-settings.zsh

# fzf tab completion
source ~/.zsh/fzf-tab-completion.zsh

# rationalize dot
source ~/.zsh/rationalize-dot.zsh

# vi mode settings
source ~/.zsh/vi-mode.zsh

# asdf completion
if [ "$(uname)" = "Darwin" ]; then
  source "$( brew --prefix asdf )/asdf.sh"
fi


# fix for zscaler if .certificates exists in home
if [ -d "$HOME/.certificates" ]; then
  export AWS_CA_BUNDLE=$HOME/.certificates/Certificates.pem
fi
### End of Zinit's installer chunk
