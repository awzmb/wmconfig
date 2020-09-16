# set completion path
GENCOMPL_FPATH=$HOME/.zsh/complete

# load plugin
zinit light RobSis/zsh-completion-generator

# define programs to create completions with
zstyle :plugin:zsh-completion-generator programs ggrep tr cat

