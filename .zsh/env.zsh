# --- path ---
# scripts, appimages and local binaries
export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.appimage:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# golang
export GOPATH="$HOME/.go"
export GOROOT="${HOME}/.go/go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$GOROOT/bin"
export GOSUMDB=sum.golang.org
export GOPROXY=direct

# java
export JAVA_HOME="/usr/lib/jvm/default"

# spicetify
export PATH="${PATH}:${HOME}/.spicetify"

# --- aliases ---
[[ -f ~/.aliases ]] && source ~/.aliases

# --- terminal colors ---
# Nord color palette for the linux virtual console
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
fi
