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
  k3d \
  krew \
  pass

# brew cask
brew cask install \
  alacritty \
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

# install wm and hotkey manager
#brew install \
    #koekeishiya/formulae/skhd \
    #koekeishiya/formulae/yabai
#brew services start yabai
#brew update
#brew services restart --all

# install k8s tools via asdf
