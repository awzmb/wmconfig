#!/bin/sh

# add font tap to brew cask
brew tap homebrew/cask-fonts

# default packages
brew install tmux
brew install neovim
brew install asdf
brew install ansible
brew install awscli
brew install go-task/tap/go-task
brew install grep --with-default-names
brew install jq
brew install jd
brew install git
brew install krew
brew install pass
brew install neomutt
brew install isync
brew install notmuch
brew install screen
brew install ranger
brew install htop
brew install gpg
brew install tree
brew install openssl
brew install neofetch
brew install keychain
brew install coreutils
brew install ack
brew install wget
brew install tmuxinator
brew install fzf
brew install bat
brew install gnu-sed --with-default-names
# to start isync as service run 'brew services start isync'

# brew cask
brew cask install alacritty
brew cask install brave-browser
brew cask install spotify
brew cask install karabiner-elements
brew cask install discord
brew cask install steermouse
brew cask install vscodium
brew cask install microsoft-teams
brew cask install keepassxc
brew cask install 1password
brew cask install docker
brew cask install drawio

# install coc and language server (vim)
brew install node
brew install npm
brew install yarn
brew install yaml-language-server
brew install hashicorp/tap/terraform-ls
# add certificates for npm and yarn if zscaler is running
# cat xxxx.cer >> /usr/local/etc/openssl/cert.pem might be necessary
if [ -e '~/.certificates' ]; then
  npm config set strict-ssl false && \
  yarn config set strict-ssl false
fi

# coc languages
# TODO: install automatically via vim
#:CocInstall coc-yaml
#:CocInstall coc-docker
#:CocInstall coc-python
#:CocInstall coc-gitignore

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
asdf plugin add 1password
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

# fix zsh 'insecure directory' problem
sudo chmod -R 755 /usr/local/share/zsh
sudo chown -R $(whoami):staff /usr/local/share/zsh

# install vscodium extensions
code --install-extension \
  hashicorp.terraform \
  vscodevim.vim
