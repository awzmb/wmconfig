# set completion path
GENCOMPL_FPATH=$HOME/.zsh/completions

# load plugin
zinit light RobSis/zsh-completion-generator

# define programs to create completions for
zstyle :plugin:zsh-completion-generator programs tr cat python pip
