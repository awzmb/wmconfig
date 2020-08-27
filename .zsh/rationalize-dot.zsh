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
