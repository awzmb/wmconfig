# load zsh-completions plugin
zinit light zsh-users/zsh-completions
autoload -U compinit
compinit
zmodload -i zsh/complist

WORDCHARS=''
# do not autoselect the first completion entry
unsetopt menu_complete
unsetopt flowcontrol
# show completion menu on successive tab press
setopt auto_menu
setopt complete_in_word
setopt always_to_end

# menu style completion
CASE_SENSITIVE="false"
setopt MENU_COMPLETE
setopt no_list_ambiguous
bindkey -M menuselect '^o' accept-and-infer-next-history
zstyle ':completion:*' menu yes select

# case insensitive (all), partial-word and substring completion
if [[ "$CASE_SENSITIVE" = true ]]; then
  zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
else
  if [[ "$HYPHEN_INSENSITIVE" = true ]]; then
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
  else
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
  fi
fi
unset CASE_SENSITIVE HYPHEN_INSENSITIVE

# complete . and .. special directories
zstyle ':completion:*' special-dirs true

# basic ls colors (will be overwritten if completion-colors.zsh is active
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# use caching so that commands like apt and dpkg complete are useable
if [ ! -d $CACHEDIR ]; then
  mkdir -p $CACHEDIR
fi
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path "$HOME/.zshcache"

# tab completion for PIDs
zstyle ':completion:*:*:*:*:processes' command "ps -u `whoami` -o pid,user,comm,command -w -w"
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# tab completion for process names
zstyle ':completion:*:processes-names' command 'ps axho command'

# tab completion from hostsfile
zstyle ':completion:*' hosts $(awk '/^[^#]/ {print $2 $3" "$4" "$5}' /etc/hosts | grep -v ip6- && grep "^#%" /etc/hosts | awk -F% '{print $2}')

# tab completion for ssh
# https://www.zsh.org/mla/users/2015/msg00467.html
# shellcheck disable=SC2016
zstyle -e ':completion:*:*:ssh:*:my-accounts' users-hosts \
	'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'

# cd will never select parent
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# print descriptions in a beautiful way (does not work with fzf)
#zstyle ':completion:*:descriptions' format '%B%d%b'

# warning if nothing available to complete
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'

# i dont know what it does but everybody uses it
zstyle '*' single-ignored show

# complete dots if applicable
if [[ $COMPLETION_WAITING_DOTS = true ]]; then
  expand-or-complete-with-dots() {
    # toggle line-wrapping off and back on again
    [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti rmam
    print -Pn "%{%F{red}......%f%}"
    [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti smam

    zle expand-or-complete
    zle redisplay
  }
  zle -N expand-or-complete-with-dots
  bindkey "^I" expand-or-complete-with-dots
fi

# compdump
#compinit -u -d "${HOME}/.zcompdump_${ZSH_VERSION}"
