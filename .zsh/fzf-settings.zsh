## settings
# Use ~~ as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='*'

# use fd for fzf search and do not exclude hidden files
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git --color=always"

# enable processing of ansi color codes
export FZF_DEFAULT_OPTS="--ansi"

# change marker prompt
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --prompt '»'"

# change number of spaces per tab
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --tabstop=2"

# cycle results
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --cycle"

# use base16 colors to match colorscheme
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --color=16"

# reverse layout (display first entry on top
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --layout=reverse"

# only use a certain percent of the terminal instead of full height
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --height 40%"

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
#_fzf_compgen_path() {
  #fd --hidden --follow --exclude ".git" . "$1"
#}

## Use fd to generate the list for directory completion
#_fzf_compgen_dir() {
  #fd --type d --hidden --follow --exclude ".git" . "$1"
#}

# (EXPERIMENTAL) Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
#_fzf_comprun() {
  #local command=$1
  #shift

  #case "$command" in
    #cd)           fzf "$@" --preview 'tree -C {} | head -200' ;;
    #export|unset) fzf "$@" --preview "eval 'echo \$'{}" ;;
    #ssh)          fzf "$@" --preview 'dig {}' ;;
    #*)            fzf "$@" ;;
  #esac
#}
