## fzf based autosuggestion
zinit light marlonrichert/zsh-autocomplete

# fzf based completion
zstyle ':completion:*' menu select
zstyle ':autocomplete:list-choices:*' min-input 3
zstyle ':autocomplete:list-choices:*' max-lines 80%
zstyle ':autocomplete:tab:*' completion cycle
zstyle ':autocomplete:tab:*' completion fzf
zstyle ':autocomplete:*' groups always

# fuzzy matching for typos
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

