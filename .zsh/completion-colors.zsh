# ls colors
autoload -U colors

zinit light trapd00r/LS_COLORS

# enable ls colors (uncomment to override .dir_colors
#export LSCOLORS="Gxfxcxdxbxegedabagacad"

# use LS_COLORS for completion
if [[ "$DISABLE_LS_COLORS" != "true" ]]; then
  # Find the option for using colors in ls, depending on the version
  if [[ "$OSTYPE" == (darwin|freebsd)* ]]; then
    # this is a good alias, it works by default just using $LSCOLORS
    ls -G . &>/dev/null && alias ls='ls -G'
    # only use coreutils ls if there is a dircolors customization present
    # ($LS_COLORS or .dircolors file) otherwise, gls will use the default
    # color scheme which is ugly af
    [[ -n "$LS_COLORS" || -f "$HOME/.dircolors" ]] && gls --color -d . &>/dev/null && alias ls='gls --color=tty'
  else
    # for gnu ls, we use the default ls color theme. they can later be overwritten by themes.
    if [[ -z "$LS_COLORS" ]]; then
      (( $+commands[dircolors] )) && eval "$(dircolors -b)"
    fi

    ls --color -d . &>/dev/null && alias ls='ls --color=tty' || { ls -G . &>/dev/null && alias ls='ls -G' }
    # take advantage of $ls_colors for completion as well.
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  fi
fi

setopt auto_cd
setopt multios
setopt prompt_subst
