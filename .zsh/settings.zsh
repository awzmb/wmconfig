# --- general settings ---
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

# --- tools ---
zinit param'zs_set_path' for @psprint/zsh-sweep

# --- fixes ---
# linux-specific settings
if [ "$(uname)" = "Linux" ]; then
  # xdg runtime dir for podman
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  # don't use a gui prompt for git credentials
  unset SSH_ASKPASS
fi
