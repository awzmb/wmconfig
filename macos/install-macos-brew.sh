#!/bin/sh

# add font tap to brew cask
brew tap homebrew/cask-fonts

# default packages
brew install \
  tmux \
  neovim \
  asdf \
  ansible \
  awscli \
  go-task/tap/go-task \
  grep --with-default-names \
  jq \
  jd \
  git \
  krew \
  pass \
  neomutt \
  isync \
  notmuch \
  screen \
  ranger \
  htop \
  gpg \
  tree\
  openssl \
  neofetch \
  keychain \
  coreutils \
  ack \
  wget \
  tmuxinator \
  fzf \
  gnu-sed --with-default-names
# to start isync as service run 'brew services start isync'

# brew cask
brew cask install \
  alacritty \
  brave-browser \
  spotify \
  karabiner-elements \
  discord \
  steermouse \
  vscodium \
  microsoft-teams \
  keepassxc \
  1password \
  docker

# install coc and language server (vim)
brew install \
  node \
  npm \
  yarn \
  yaml-language-server \
  hashicorp/tap/terraform-ls
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
brew cask install \
  dmenu-mac
# to turn off spotlight, follow https://www.fireebok.com/resource/how-to-turn-off-and-turn-on-spotlight-on-macos-mojave.html

# fonts
brew cask install \
  font-terminus \
  font-hack \
  font-edlo \
  font-dejavu \
  font-bitstream-vera-sans-mono-nerd-font \
  font-proggy-clean-tt-nerd-font

# spotify with terminal client
brew install \
  portaudio \
  spotifyd \
  spotify-tui
# start with brew services start spotifyd
# init gpg key with 'gpg --full-gen-key'
# store password with 'pass insert spotify'

# install wm and hotkey manager
brew install \
    koekeishiya/formulae/skhd \
    koekeishiya/formulae/yabai
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
