# --- plugins ---
autoload -U colors
zinit light trapd00r/LS_COLORS
zinit light zsh-users/zsh-completions
zinit light RobSis/zsh-completion-generator

GENCOMPL_FPATH=$HOME/.zsh/gencompl
zstyle :plugin:zsh-completion-generator programs tr cat python pip

# --- ls colors ---
if [[ "$DISABLE_LS_COLORS" != "true" ]]; then
  if [[ "$OSTYPE" == (darwin|freebsd)* ]]; then
    ls -G . &>/dev/null && alias ls='ls -G'
    [[ -n "$LS_COLORS" || -f "$HOME/.dircolors" ]] && gls --color -d . &>/dev/null && alias ls='gls --color=tty'
  else
    # run after plugin so ~/.dircolors overrides the plugin's colors if present
    (( $+commands[dircolors] )) && eval "$(dircolors -b)"
    ls --color -d . &>/dev/null && alias ls='ls --color=tty' || { ls -G . &>/dev/null && alias ls='ls -G' }
  fi
fi

# --- zstyle ---
zmodload -i zsh/complist
WORDCHARS=''
unsetopt menu_complete
unsetopt flowcontrol
setopt auto_menu
setopt complete_in_word
setopt always_to_end
setopt auto_cd
setopt multios
setopt prompt_subst

CASE_SENSITIVE="false"
setopt MENU_COMPLETE
setopt no_list_ambiguous
bindkey -M menuselect '^o' accept-and-infer-next-history
zstyle ':completion:*' menu yes select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

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

zstyle ':completion:*' special-dirs true
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path "$HOME/.zshcache"
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:processes-names' command 'ps axho command'
zstyle ':completion:*' hosts $(awk '/^[^#]/ {print $2 $3" "$4" "$5}' /etc/hosts | grep -v ip6- && grep "^#%" /etc/hosts | awk -F% '{print $2}')
zstyle -e ':completion:*:*:ssh:*:my-accounts' users-hosts \
'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle '*' single-ignored show

# --- compinit ---
fpath=(~/.zsh/completions $fpath)
autoload -U +X bashcompinit && bashcompinit
compinit

# --- fzf-tab (must load after compinit) ---
zinit light Aloxaf/fzf-tab

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':completion:complete:*:options' sort false
zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# --- github cli completions ---
zstyle ':completion:*:*:gh-run-view:*' fzf-completion-opts \
    --preview 'gh run view {1} --log --no-color' \
    --preview-window=right:70% \
    --ansi \
    --header="Select a GitHub Run" \
    --bind "ctrl-/:toggle-preview"

_gh_run_view_completion() {
    local -a runs
    runs=( $(gh run list --jq '.[] | "\(.databaseId)\t\(.displayTitle)"' --no-color | \
              awk -F'\t' '{print $1":"$2}') )
    _describe 'workflow runs' runs
}

zstyle ':completion:*:*:gh-pr-checkout:*' fzf-completion-opts \
    --preview 'gh pr view {1} --json title,url,author,state --jq ".title" --no-color' \
    --preview-window=up:60% \
    --ansi \
    --header="Select a GitHub Pull Request" \
    --bind "ctrl-/:toggle-preview"

_gh_pr_checkout_completion() {
    local -a prs
    prs=( $(gh pr list --state open --jq '.[] | "\(.number)\t\(.title)"' --no-color | \
             awk -F'\t' '{print $1":"$2}') )
    _describe 'pull requests' prs
}

compdef _gh_run_view_completion gh-run-view
compdef _gh_pr_checkout_completion gh-pr-checkout

# --- tool completions ---
[[ -f "${HOME}/.completion/gcloud/completion.zsh.inc" ]] && \
    source "${HOME}/.completion/gcloud/completion.zsh.inc"

command -v gh        > /dev/null && source <(gh completion -s zsh)
command -v devpod    > /dev/null && source <(devpod completion zsh)
command -v timetrace > /dev/null && source <(timetrace completion zsh)
command -v talosctl  > /dev/null && source <(talosctl completion zsh)
command -v terraform > /dev/null && complete -o nospace -C "${HOME}/.bin/terraform" terraform
command -v aws_completer > /dev/null && complete -C aws_completer aws

compdef mosh=ssh
command -v tt > /dev/null && export SHEET_FILE="${HOME}/.timesheets/timesheet.json"
