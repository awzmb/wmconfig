# source theme
source ~/.zsh/theme.zsh

# aliases
source ~/.aliases

# add script folder to path
export PATH="~/.scripts:$PATH"

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

# ensure we have correct locale set (this is mostly for MacOS)
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# umask
umask 022

# editor/visual
if type nvim >/dev/null 2>&1; then
# neovim
  export EDITOR=nvim
  export VISUAL=nvim
else
# vim (without support for tmp/current.vim)
  export EDITOR=vim
  export VISUAL=vim
fi

# colored ls (one version for GNU, other for macos)
if whence dircolors > /dev/null; then
  eval "`dircolors -b`"
  alias ls='ls --color=auto'
else
  export CLICOLOR=1
fi

# load completion
autoload -Uz compinit; compinit
_comp_options+=(globdots) # With hidden files

# make less always work with colored input
alias less='less -R'

# # make watch always work with colored input
alias watch='watch --color'

# pager
export PAGER=less

# zsh will not beep
setopt no_beep

# make cd push the old directory onto the directory stack
setopt auto_pushd

# Report the status of background jobs immediately, rather than waiting until just before printing a prompt.
setopt notify

# Turn off terminal driver flow control (CTRL+S/CTRL+Q)
setopt noflowcontrol
stty -ixon -ixoff

# Do not kill background processes when closing the shell.
setopt nohup

# zsh history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=${HISTSIZE}

# make some commands not show up in history
export HISTIGNORE="ls:ll:cd:cd -:pwd:exit:date:* --help"

# multiple zsh sessions will append to the same history file (incrementally, after each command is executed)
setopt inc_append_history

# purge duplicates first
setopt hist_expire_dups_first

# if a new command line being added to the history list duplicates an older one, the older command is removed from the list
setopt hist_ignore_all_dups

# prefix a command with a space to keep it out of the history
setopt hist_ignore_space

# reduce unnecessary blanks from commands being written to history
setopt hist_reduce_blanks

# import new commands from history (mostly)
setopt share_history

# fuzzy matching for typos
#zstyle ':completion:*' completer _complete _match _approximate
#zstyle ':completion:*:match:*' original only
#zstyle ':completion:*:approximate:*' max-errors 1 numeric

# menu style completion
CASE_SENSITIVE="false"
setopt MENU_COMPLETE
setopt no_list_ambiguous
zstyle ':completion:*' menu yes select

# fzf based completion
#zstyle ':completion:*' menu select
#zstyle ':autocomplete:list-choices:*' min-input 3
#zstyle ':autocomplete:list-choices:*' max-lines 80%
#zstyle ':autocomplete:tab:*' completion cycle
#zstyle ':autocomplete:tab:*' completion fzf
#zstyle ':autocomplete:*' groups always

# tab completion for PIDs
zstyle ':completion:*:*:*:*:processes' command "ps -u `whoami` -o pid,user,comm,command -w -w"
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# cd will never select parent
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# cache completions
#if [ ! -d $CACHEDIR ]; then
  #mkdir -p $CACHEDIR
#fi
#CACHEDIR="$HOME/.zsh/cache"
#zstyle ':completion:*' use-cache on
#zstyle ':completion:*' cache-path $CACHEDIR

# completions
compinit -u -d "${HOME}/.zcompdump_${ZSH_VERSION}"

# https://www.zsh.org/mla/users/2015/msg00467.html
# shellcheck disable=SC2016
zstyle -e ':completion:*:*:ssh:*:my-accounts' users-hosts \
	'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'

# allow ssh tab completion for mosh hostnames
compdef mosh=ssh

# install fzf
#zinit ice from"gh-r" as"command"
#zinit load junegunn/fzf-bin

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

# load bashcompinit for some old bash completions
autoload bashcompinit && bashcompinit

# use the vi navigation keys (hjkl) besides cursor keys in menu completion
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char        # left
bindkey -M menuselect 'k' vi-up-line-or-history   # up
bindkey -M menuselect 'l' vi-forward-char         # right
bindkey -M menuselect 'j' vi-down-line-or-history # bottom

# asdf completion
if [ "$(uname)" = "Darwin" ]; then
  source "$( brew --prefix asdf )/asdf.sh"
fi


##### vi mode settings

# Remove mode switching delay.
KEYTIMEOUT=5

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'

  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# Use beam shape cursor on startup.
echo -ne '\e[5 q'

# Use beam shape cursor for each new prompt.
preexec() {
   echo -ne '\e[5 q'
}

# fix for zscaler if .certificates exists in home
if [ -d "$HOME/.certificates" ]; then
  export AWS_CA_BUNDLE=$HOME/.certificates/Certificates.pem
fi
### End of Zinit's installer chunk
