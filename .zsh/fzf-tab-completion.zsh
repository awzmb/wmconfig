### fzf tab completion (partially overwrites general settings)
## module
zinit light Aloxaf/fzf-tab

# disable sort when completing options of any command
zstyle ':completion:complete:*:options' sort false

# use input as query string when completing zlua
zstyle ':fzf-tab:complete:_zlua:*' query-string input

# (experimental, may change in the future)
# some boilerplate code to define the variable `extract` which will be used later
# please remember to copy them
local extract="
# trim input(what you select)
local in=\${\${\"\$(<{f})\"%\$'\0'*}#*\$'\0'}
# get ctxt for current completion(some thing before or after the current word)
local -A ctxt=(\"\${(@ps:\2:)CTXT}\")
# real path
local realpath=\${ctxt[IPREFIX]}\${ctxt[hpre]}\$in
realpath=\${(Qe)~realpath}
"

# give a preview of commandline arguments when completing `kill`
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap

# give a preview of directory by exa when completing cd
zstyle ':fzf-tab:complete:cd:*' extra-opts --preview=$extract'exa -1 --color=always $realpath'

## command
FZF_TAB_COMMAND=(
  fzf
    #--ansi   # Enable ANSI color support, necessary for showing groups
    --expect='$continuous_trigger,$print_query' # For continuous completion and print query
    #'--color=hl:$(( $#headers == 0 ? 108 : 255 ))'
    #--nth=2,3 --delimiter='\x00'  # Don't search prefix
    #--layout=reverse --height='${FZF_TMUX_HEIGHT:=75%}'
    #--tiebreak=begin -m --bind=tab:down,btab:up,change:top,ctrl-space:toggle --cycle
    '--query=$query'   # $query will be expanded to query string at runtime.
    '--header-lines=$#headers' # $#headers will be expanded to lines of headers at runtime
    --print-query
)
zstyle ':fzf-tab:*' command $FZF_TAB_COMMAND

### legacy stuff (replaced by native fzf zsh)
## open fzf search with ctrl+o
# function to open fzf
#_start_fzf_vim_search() {
	#zle -I
	#(
		#vim $(fzf)
	#) < /dev/tty
#}
#autoload _start_fzf_vim_search
#zle -N _start_fzf_vim_search

# function to open fzf history search
#_start_fzf_history_search() {
  #BUFFER=$(history -t '%Y-%m-%d %H:%M:%S' 0 | grep -v 1969 | fzf +s +m -x --tac -e -q "$BUFFER" | awk '{print substr($0, index($0, $4))}')
  #zle end-of-line
#}
#_start_fzf_history_search() {
  #BUFFER=$(history -t '%Y-%m-%d %H:%M:%S' 0 | grep -v 1969 | fzf +s +m -x --tac -e -q "$BUFFER" | awk '{print substr($0, index($0, $4))}')
  #zle end-of-line
#}
#autoload _start_fzf_history_search
#zle -N _start_fzf_history_search

# keybinding (ctrl+o for vim search, ctrl+r for history search)
#bindkey '^o' _start_fzf_vim_search
#bindkey '^r' _start_fzf_history_search
