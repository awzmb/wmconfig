#!/bin/sh
sudo pacman -Sy \
  file-roller \
  jdk8-openjdk \
  scrot \
  firefox \
  compton \
  xfce4-settings \
  lxterminal \
  blueman \
  docker \
  docker-compose \
  python-docker \
  pcmanfm \
  atom \
  steam \
  feh \
  lxappearance \
  lxterminal \
  nitrogen \
  xfce4-power-manager \
  zsh \
  zsh-syntax-highlighting \
  zsh-completions \
  pavucontrol \
  pulseaudio &&
sudo pacman -S --needed \
  base-devel \
  git \
  wget \
  lsb-release \
  ttf-hack \
  evince \
  terminus-font \
  pass \
  neomutt \
  ranger \
  gnupg \
  mpg123 \
  tlp \
  calcurse \
  libcaca \				#provides img2txt
  python-pylint \			#python checker / debugger
  && \
gpg --full-gen-key && \
pass init dennis.bundschuh@ancud.de \
pass insert Mail/main
