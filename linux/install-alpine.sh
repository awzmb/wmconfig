#!/bin/sh
# Warning: 'apk add sudo && sudo -lU [name]' before using this script

# basic packages
sudo apk add \
  vim zsh bash neovim tmux pass \
  openssl curl bat w3m exa zip \
  ctags zsh-vcs python3 ack p7zip \
  coreutils tree ranger nodejs \
  npm yarn curl wget

# additional stuff
sudo apk add \
  terraform ansible aws-cli py3-pip

# python packages
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
