#!/bin/sh

# disable verification
sudo spctl --master-disable

# change hostname
sudo scutil --set HostName bawzmbp

#/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Disable Notification Center and remove the menu bar icon
launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

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
  grep \
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
  gpg
# to start isync as service run 'brew services start isync'

# brew cask
brew cask install \
  alacritty \
  brave-browser \
  amethyst \
  spotify \
  karabiner-elements \
  discord \
  steermouse \
  vscodium \
  microsoft-teams \
  keepassxc \
  1password \
  docker

# install dmenu port and disable spotlight
brew cask install \
  dmenu-mac
# to turn off spotlight, follow https://www.fireebok.com/resource/how-to-turn-off-and-turn-on-spotlight-on-macos-mojave.html

# fonts
brew cask install \
  font-terminus \
  font-hack

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

# fix insecure directory problem
sudo chmod -R 755 /usr/local/share/zsh
sudo chown -R $(whoami):staff /usr/local/share/zsh
