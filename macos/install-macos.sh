#!/bin/sh

# disable verification
sudo spctl --master-disable

#/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# add font tap to brew cask
brew tap homebrew/cask-fonts

# default packages
brew install \
  tmux \
  neovim

# brew cask
brew cask install \
  alacritty \
  spotify \
  karabiner-elements

