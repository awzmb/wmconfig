#!/bin/sh

# updating packages and package list
sudo apt update && sudo apt -y upgrade

# basic packages
sudo apt -y install \
  curl \
  git \
  vim \
  nodejs \
  zsh \
  python \
  tmux \
  fzf \
  jq \
  jd \
  pass \
  screen \
  gpg \
  tree \
  wget \
  tmuxinator \
  w3m \
  openssl \
  fd-find \
  exa

# change default shell to zsh
chsh -s /usr/bin/zsh
sudo chsh -s /usr/bin/zsh

# install spotify streaming client
sudo apt install =y \
  apt-transport-https \
  alsa-utils
curl -sSL https://dtcooper.github.io/raspotify/key.asc | sudo apt-key add -v -
echo 'deb https://dtcooper.github.io/raspotify raspotify main' | sudo tee /etc/apt/sources.list.d/raspotify.list
sudo apt update
sudo apt install raspotify

