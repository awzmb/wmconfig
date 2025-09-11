### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

### custom configuration
# vi bindings
bindkey -v

# modules (turbo mode)
zinit ice wait'!0'

# colorizes various shell tools (grep, diff, ip, ...)
# NOTE: currently disabled because alpine busybox does not support certain grep options
#zinit light zpm-zsh/colorize
#
# change login terminal colors
if [ "$TERM" = "linux" ]; then
    echo -en "\e]P0242933" #black
    echo -en "\e]P83B4252" #darkgrey
    echo -en "\e]P1BF616A" #darkred
    echo -en "\e]P9BF616A" #red
    echo -en "\e]P2A3BE8C" #darkgreen
    echo -en "\e]PAA3BE8C" #green
    echo -en "\e]P3EBCB8B" #brown
    echo -en "\e]PBEBCB8B" #yellow
    echo -en "\e]P481A1C1" #darkblue
    echo -en "\e]PC81A1C1" #blue
    echo -en "\e]P5B48EAD" #darkmagenta
    echo -en "\e]PDB48EAD" #magenta
    echo -en "\e]P688C0D0" #darkcyan
    echo -en "\e]PE88C0D0" #cyan
    echo -en "\e]P7E5E9F0" #lightgrey
    echo -en "\e]PFD8DEE9" #white
    #clear #for background artifacting
fi

# aliases
source ~/.aliases

# add script and appimage to path
export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.appimage:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# add snap to path on linux
if [ "$(uname)" = "Linux" ]; then
  export PATH="/snap/bin:$PATH"
fi

# add golaang path
export GOPATH="$HOME/.go"
export GOROOT="${HOME}/.go/go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$GOROOT/bin"
export GOSUMDB=sum.golang.org
export GOPROXY=direct

# source theme
source ~/.zsh/theme.zsh

# completion settings
source ~/.zsh/completion-settings.zsh

# change ls colors to match system
source ~/.zsh/completion-colors.zsh

# general settings
source ~/.zsh/general-settings.zsh

# rationalize dot
source ~/.zsh/rationalize-dot.zsh

# vi mode settings
source ~/.zsh/vi-mode.zsh

# tab completion generator
source ~/.zsh/completion-generator.zsh

# fzf integration
source ~/.zsh/fzf-settings.zsh
source ~/.zsh/fzf-completion.zsh
source ~/.zsh/fzf-keybindings.zsh

# fzf tab completion
source ~/.zsh/fzf-tab-completion.zsh

# tab completion github cli
source ~/.zsh/completion-github-cli.zsh

# several fixes for different systems
source ~/.zsh/fixes.zsh

# additional tools
source ~/.zsh/tools.zsh

# additional stuff
if [ "$(uname)" = "Linux" ]; then
  # dont use gui to enter git credentials
  unset SSH_ASKPASS
  # keyboard layout
  #setxkbmap us -variant altgr-intl
  # use caps as escape button
  #setxkbmap -option caps:escape
  #export XDG_RUNTIME_DIR=$HOME/.tmp
fi

# trigger completion initialization
compinit

# openjdk
# export PATH="${PATH}:${HOME}/.jdk/openjdk-11/bin"
# export JAVA_HOME="${HOME}/.jdk/openjdk-11"
export JAVA_HOME="/usr/lib/jvm/default"

#
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=$PATH:/home/awzm/.spicetify

# add pip local cache to path
export PATH="${PATH}:${HOME}/.local/bin"

#if type "gcloud" > /dev/null; then
   #source /usr/share/google-cloud-sdk/completion.zsh.inc
#fi

# gcloud completion
if [ -f "${HOME}/.completion/gcloud/completion.zsh.inc" ]; then
   source ${HOME}/.completion/gcloud/completion.zsh.inc
fi

# extra completions
command -v gh > /dev/null && . <(gh completion -s zsh)
command -v timetrace > /dev/null && . <(timetrace completion zsh)
command -v flux > /dev/null && . <(flux completion zsh)
command -v helm > /dev/null && . <(helm completion zsh)
command -v kubectl > /dev/null && . <(kubectl completion zsh --request-timeout 0.0001)
# timesheet file
command -v tt > /dev/null && export SHEET_FILE="${HOME}/.timesheets/timesheet.json"

# spicetify
export PATH=$PATH:/home/bawzm/.spicetify

if [ -e /home/bawzm/.nix-profile/etc/profile.d/nix.sh ]; then . /home/bawzm/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

# use iHD driver if intel iris graphics are present
#if [ "$(uname --machine)" = "x86_64" ]; then
  #IRIS_VGA_PRESENT=$(lspci -nnk | grep -iA2 vga | grep -i 'iris')
  #if [[ -n "${IRIS_VGA_PRESENT}" ]]; then
    #export LIBVA_DRIVER_NAME=iHD
  #fi
#fi

export PATH=$PATH:/home/dbundschuh/.spicetify

export PATH=$PATH:/var/home/awzm/.spicetify

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/awzm/extract/google-cloud-sdk/path.zsh.inc' ]; then . '/home/awzm/extract/google-cloud-sdk/path.zsh.inc'; fi

# docker aliases completion
source ~/.zsh/completion-aliases-docker.zsh

# tool versions
export TERRAFORM_VERSION="1.7.5"

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /home/awzm/.bin/terraform terraform

source /home/awzm/.config/broot/launcher/bash/br
