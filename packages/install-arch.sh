#!/bin/sh
sudo pacman -Sy \
  jdk8-openjdk \
  scrot \				# screenshots
  firefox \
  compton \				# transparency and tearing removal
  xfce4-settings \			# cool settings manager for quick changes
  rxvt-unicode \			# primary terminal emulator
  lxterminal \				# secondary terminal emulator
  blueman \
  docker \				
  docker-compose \			
  ansible \				
  python-docker \			# ansible dependency
  pcmanfm \				# graphical file manager
  atom \				# graphical editor
  pass \				# simple password manager
  steam \				
  lxappearance \
  nitrogen \				# wallpaper manager
  xfce4-power-manager \
  zsh \
  zsh-syntax-highlighting \
  zsh-completions \
  pavucontrol \				# graphical sound manager
  pulseaudio &&
sudo pacman -S --needed \
  base-devel \
  git \
  wget \
  lsb-release \
  ttf-hack \				# secondary font
  evince \				# pdf viewer
  terminus-font \			# main fonts
  neomutt \				# email client
  notmuch \				# email tagging
  isync \				# email imap synchronisation
  msmtp \				# send mail
  ranger \				# primary file manager
  gnupg \
  mpg123 \
  tlp \
  calcurse \
  libcaca \				# provides img2txt
  python-pylint \			# python checker / debugger
  && \
gpg --full-gen-key && \
pass init dennis.bundschuh@ancud.de \
pass insert Mail/main
