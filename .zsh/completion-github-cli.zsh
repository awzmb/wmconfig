## function to get github run ids and titles
#_gh_run_fzf_select() {
    #gh run list --jq '.[] | "\(.databaseId)\t\(.displayTitle)"' --no-color | \
    #fzf --ansi --header="Select a GitHub Run" \
        #--with-nth="1.."\
        #--delimiter='\t' \
        #--preview 'gh run view {1} --log --no-color' \
        #--preview-window=right:70% \
        #--reverse \
        #--bind "ctrl-/:toggle-preview" \
        #--print-column=1
#}

## wrapper function for gh run view
#gh_run_view_fzf() {
    #local selected_run_id
    #selected_run_id="$(_gh_run_fzf_select)"
    #if [[ -n "$selected_run_id" ]]; then
        #BUFFER="gh run view ${selected_run_id}"
        #zle accept-line
    #else
        #zle send-break # Clear the line or do nothing if nothing selected
    #fi
#}

## Bind a key to the function (e.g., Alt+v, or define an alias)
#zle -N gh_run_view_fzf
#bindkey "^[v" gh_run_view_fzf # Binds Alt+v to the function
# alias grv="gh_run_view_fzf"

# custom fzf-tab options for gh run view
zstyle ':completion:*:*:gh-run-view:*' fzf-completion-opts \
    --preview 'gh run view {1} --log --no-color' \
    --preview-window=right:70% \
    --ansi \
    --header="Select a GitHub Run" \
    --bind "ctrl-/:toggle-preview"

# define a custom completion function for gh run view to format its output for fzf
# this overrides the default _gh completion for gh run view
_gh_run_view_completion() {
    local -a runs
    # fetch runs, format them as id<tab>title
    runs=( $(gh run list --jq '.[] | "\(.databaseId)\t\(.displayTitle)"' --no-color | \
              awk -F'\t' '{print $1":"$2}') ) # Format for Zsh completion
    _describe 'workflow runs' runs
}

# For gh pr checkout (using fzf-tab)
zstyle ':completion:*:*:gh-pr-checkout:*' fzf-completion-opts \
    --preview 'gh pr view {1} --json title,url,author,state --jq ".title" --no-color' \
    --preview-window=up:60% \
    --ansi \
    --header="Select a GitHub Pull Request" \
    --bind "ctrl-/:toggle-preview"

_gh_pr_checkout_completion() {
    local -a prs
    # List PRs, format as ID:Title
    prs=( $(gh pr list --state open --jq '.[] | "\(.number)\t\(.title)"' --no-color | \
             awk -F'\t' '{print $1":"$2}') )
    _describe 'pull requests' prs
}

# register the custom completion function for 'gh run view'
compdef _gh_run_view_completion gh-run-view
compdef _gh_pr_checkout_completion gh-pr-checkout
