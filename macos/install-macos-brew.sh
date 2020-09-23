#!/bin/sh

# add font tap to brew cask
brew tap homebrew/cask-fonts

# default packages
brew install tmux # terminal multiplexer
brew install neovim # editor
brew install asdf # manage dev related cli tools (terraform, kubectl,..)
brew install ansible # configuration management
brew install go # go lang binary
brew install go-task/tap/go-task # better make
brew install grep --with-default-names # gnu grep (executed via ggrep)
brew install jq # parse json
brew install jd # post stdout as json
brew install git # git
brew install krew # kubectl plugin manager
brew install pass # gnu cli password manager
brew install neomutt # read mail
brew install isync # sync mail
brew install notmuch # search and tag mail
brew install screen # gnu screen (if for some reason tmux is not applicable)
brew install ranger # file manager
brew install htop # resource monitor
brew install gpg # decrypt and encrypt files
brew install tree # show directory content as tree
brew install openssl
brew install neofetch # system information
brew install keychain
brew install coreutils
brew install ack # grep-like text finder
brew install wget # load files via http/https
brew install tmuxinator # manage tmux sessions (ide setup)
brew install fzf # fuzzy finder (essential)
brew install bat # cat with syntax highlighting
brew install fd # faster find alternative
brew install w3m # cli browser
brew install navi # read cheatsheets cli
brew install gnu-sed # gnu sed (executed via gsed)
brew install newsboat # terminal rss news reader
brew install catimg # render images in terminal
brew install exa # new old editor (for preview with fzf)
brew install reattach-to-user-namespace # copy to system clipboard from vim and tmux
# to start isync as service run 'brew services start isync'

# python stuff for coding and terminal interfaces
sudo -H python -m ensurepip
pip install \
  markdown \
  html2text \
  requests \
  beautifulsoup4 \
  pyyaml \
  pyxdg \
  pytz \
  python-dateutil \
  urwid

# brew cask
brew cask install alacritty # terminal emulator
brew cask install brave-browser # google chrome alternative
brew cask install spotify # music
brew cask install karabiner-elements # modify keyboard input
brew cask install discord # slack for gaming
brew cask install steermouse # improve macos default mouse speed acceleration
brew cask install vscodium # visual studio code as foss
brew cask install microsoft-teams # most hated collaboration client
brew cask install keepassxc # manage keepass
brew cask install 1password # onepass client
brew cask install docker # container
brew cask install drawio # draw flowcharts, graphs and models
brew cask install whichspace # show current space number in dock
brew cask install monitorcontrol # control brightness and volume on external display

# aws and azure tools
brew install awscli # amazon web services cli
brew install aws-iam-authenticator # aws iam authentication for eks
brew install aws-shell # interactive awscli alternative
brew install azure-cli # microsoft azure cli
brew cask install aws-vpn-client # aws vpn for safe connections to account

# install coc and language server (vim)
brew install node
brew install npm
brew install yarn
brew install hashicorp/tap/terraform-ls
# add certificates for npm and yarn if zscaler is running
# cat xxxx.cer >> /usr/local/etc/openssl/cert.pem might be necessary
if [ -e '~/.certificates' ]; then
  npm config set strict-ssl false && \
  yarn config set strict-ssl false
fi

# zsh completions
wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh -O /usr/local/share/zsh/site-functions/_tmuxinator

# install dmenu port and disable spotlight
brew cask install dmenu-mac
# to turn off spotlight, follow https://www.fireebok.com/resource/how-to-turn-off-and-turn-on-spotlight-on-macos-mojave.html

# fonts
brew cask install font-terminus
brew cask install font-hack
brew cask install font-edlo
brew cask install font-dejavu
brew cask install font-bitstream-vera-sans-mono-nerd-font
brew cask install font-proggy-clean-tt-nerd-font
brew cask install font-cozette

# spotify with terminal client
brew install portaudio
brew install spotifyd
brew install spotify-tui
# start with brew services start spotifyd
# init gpg key with 'gpg --full-gen-key'
# store password with 'pass insert spotify'

# install wm and hotkey manager
brew install koekeishiya/formulae/skhd
brew install koekeishiya/formulae/yabai
brew services start yabai
brew services start skhd
brew update
brew services restart --all

# install k8s tools via asdf
asdf plugin add bat
asdf plugin add eksctl
asdf plugin add helm
asdf plugin add helm-cr
asdf plugin add helm-docs
asdf plugin add helmfile
asdf plugin add k3d
asdf plugin add k9s
asdf plugin add kubectl
asdf plugin add kubectx
asdf plugin add kubeseal
asdf plugin add terraform
asdf plugin add terraform-docs
asdf plugin add terraform-lsp
asdf plugin add terraform-validator
asdf plugin add terragrunt

# terraform tools
brew install transcend-io/tap/terragrunt-atlantis-config

# fix zsh 'insecure directory' problem
sudo chmod -R 755 /usr/local/share/zsh
sudo chown -R $(whoami):staff /usr/local/share/zsh

# install vscodium extensions
#code --install-extension \
#  hashicorp.terraform \
#  vscodevim.vim

# finally upgrade packages if already installed
brew update && brew upgrade
