#!/bin/sh

# NOTE: this installer script has been tested only on the
# debian testing branch. some packages might not be available
# on debian stable

# add non-free and contrib to sources.list
sudo dpkg --add-architecture i386

# update packages to current level
sudo apt update && sudo apt upgrade

ORIGIN_PATH=${pwd}

# install linux proprietary gpu firmware
sudo apt -y install \
  firmware-linux \
  firmware-linux-nonfree

# basic packages
sudo apt -y install \
  zsh \
  vim \
  neovim \
  vifm \
  vim \
  neovim \
  xss-lock \
  picom \
  pavucontrol \
  calc \
  unrar \
  exa \
  bat \
  jq \
  tree \
  ack \
  git \
  fd-find \
  sudo \
  fzf \
  curl \
  wget \
  tmux \
  ranger

# additional desktop packages
sudo apt -y install \
  i3 \
  rofi \
  wofi \
  feh \
  polybar \
  powertop \
  dunst \
  xautolock \
  nitrogen \
  paper-icon-theme \
  inkscape \
  redshift \
  redshift-gtk \
  pulsemixer \
  scrot \
  grim \
  slurp \
  lightdm \
  lightdm-greeter-gtk \
  lightdm-settings \
  terminology \
  kanshi

# install wayland i3 replacement
sudo apt -y install \
  sway \
  swaybar \
  xwayland

# install js stuff (mainly for coc)
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt -y install yarn

# install bluetooth applet
sudo apt -y install \
  blueman

# install spotify client
curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt update
sudo apt -y install spotify-client

# install ms core fonts
sudo apt -y install ttf-mscorefonts-installer

# brave browser and premise
sudo apt -y install \
  apt-transport-https \
  software-properties-common

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update && sudo apt -y install brave-browser

# workaround fd command
sudo ln -s /usr/bin/fdfind /usr/bin/fd

# install fonts
sudo apt -y install \
  fonts-terminus \
  fonts-terminus-otb \
  fonts-unifont \
  fonts-hack

# podman (docker replacement)
sudo apt -y install \
  podman \
  podman-docker

# ansible packages
sudo apt -y install \
  ansible \
  ansible-lint

# password storage
sudo apt -y install \
  pass

# python environment
sudo apt -y install \
  pipenv \
  python3-autopep8 \
  yamllint
pip install flashfocus

# enable tlp power management
sudo apt -y install tlp tlp-rdw
sudo systemctl enable tlp

# install polybar-reload script
pip install --user polybar-reload

# common media players
sudo apt -y install \
  vlc

# zathura document viewer
sudo apt install -y \
  zathura

# browser
sudo apt -y install \
  firejail \
  surf

# flashfocus
sudo apt -y install python3-xcffib
sudo pip install flashfocus

# vulkan graphics
sudo apt -y install \
  vulkan-tools

# wine and dxvk
sudo apt -y install \
  lutris \
  wine

# install mutt-wizard
git clone https://github.com/LukeSmithxyz/mutt-wizard
cd mutt-wizard
sudo make install
cd ${ORIGIN_PATH}
rm -rf mutt-wizard

# terminal tools and software
sudo apt -y install \
  w3m \
  w3m-img \
  python3-neovim \
  calcurse \
  elinks \
  newsboat \
  neofetch

# email tools
sudo apt -y install \
  neomutt \
  isync \
  notmuch \
  notmuch-mutt \
  abook

# install gtk themes
sudo apt -y install \
  arc-theme \
  paper-icon-theme \
  lxappearance

# password management
sudo apt -y install gnupg
if [ ! -d "${HOME}/.gnupg" ]; then
  gpg --full-gen-key
fi
pass init bundschuh.dennis@gmail.com
pass insert mail/main

# aws tools
sudo apt -y install \
  awscli

# aws eks tools
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# theme hospital foss
# sudo apt -y install corsix-th corsix-th-data

# julius (caesarIII clone)
# sudo apt -y install julius

# dwarf fortress
# sudo apt -y install dwarffortress

# 8bitdo SF30 bluetooth controller settings
sudo wget https://goo.gl/H2SViY -O /etc/udev/rules.d/99-8bitdo-bluetooth-controllers.rules

# use macchanger with netctl
#sudo touch /etc/netctl/interfaces/wlp2s0
#sudo echo "#!/usr/bin/env sh" >> /etc/netctl/interfaces/wlp2s0
#sudo echo "/usr/bin/macchanger -r interface" >> /etc/netctl/interfaces/wlp2s0
#sudo chmod +x /etc/netctl/interfaces/wlp2s0

# install steam gaming platform
sudo apt -y install steam

# additional stuff
unset $SSH_ASKPASS

# githubcli
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# workaround: remove xdg-desktop-portal services to prevent slow
# launch of some gtk apps (common problem with debian)
sudo apt remove \
  xdg-desktop-portal \
  xdg-desktop-portal-wlr
