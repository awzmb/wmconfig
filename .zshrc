# source theme
source ~/.zsh/theme.zsh

# aliases
source ~/.aliases

# add script folder to path
export PATH="~/scripts:$PATH"

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
zinit light marlonrichert/zsh-autocomplete
zinit light zdharma/fast-syntax-highlighting
zinit light zpm-zsh/colorize

# styles and completions
autoload -Uz compinit
compinit -u -d "${HOME}/.zcompdump_${ZSH_VERSION}"

# https://www.zsh.org/mla/users/2015/msg00467.html
# shellcheck disable=SC2016
zstyle -e ':completion:*:*:ssh:*:my-accounts' users-hosts \
	'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'

# allow ssh tab completion for mosh hostnames
compdef mosh=ssh

# install fzf
zinit ice from"gh-r" as"command"
zinit load junegunn/fzf-bin

# rastonalize dot module
rationalise-dot() {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+=/..
  else
    LBUFFER+=.
  fi
}

zle -N rationalise-dot
bindkey . rationalise-dot
# without the following, typing a period aborts incremental history search
bindkey -M isearch . self-insert

# zstyle
zstyle ':completion:*' menu select
zstyle ':autocomplete:list-choices:*' min-input 3
zstyle ':autocomplete:list-choices:*' max-lines 80%
zstyle ':autocomplete:*' groups always

# use the vi navigation keys (hjkl) besides cursor keys in menu completion
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char        # left
bindkey -M menuselect 'k' vi-up-line-or-history   # up
bindkey -M menuselect 'l' vi-forward-char         # right
bindkey -M menuselect 'j' vi-down-line-or-history # bottom
