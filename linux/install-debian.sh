#!/bin/sh

# update packages to current level
sudo apt update && sudo apt upgrade

ORIGIN_PATH=${pwd}

# basic packages
sudo apt -y install \
    zsh \
    vim \
    neovim \
    vifm \
    util-linux-user \
    i3 \
    rofi \
    redshift \
    redshift-gtk \
    vim neovim \
    xss-lock \
    picom \
    pavucontrol \
    nitrogen \
    feh \
    paper-icon-theme \
    calc \
    inkscape \
    unrar \
    exa \
    bat \
    jq \
    jd \
    tree \
    ack \
    git \
    fd-find \
    sudo \
    fzf

# workaround fd command
sudo ln -s /usr/bin/fdfind /usr/bin/fd

# install fonts
sudo apt -y install \
    terminus-fonts \
    terminus-fonts-console

# podman
sudo apt -y install \
    podman \
    podman-compose

# password storage
sudo apt -y install \
    pass \
    passmenu

# python environment
sudo apt -y install \
    pipenv \
    python3-autopep8 \
    python3-pands \
    yamllint

# enable tlp power management
sudo apt -y install tlp tlp-rdw
sudo systemctl enable tlp

# install polybar-reload script
pip install --user polybar-reload

# common media players
sudo apt -y install \
    vlc \
    vlc-extras

# zathura document viewer
sudo apt install -y \
    zathura \
    zathura-pdf-mupdf

# browser
sudo apt -y install \
    chromium-browser-privacy \
    firejail surf

# polybar
sudo apt -y install \
    polybar \
    fontawesome-fonts \
    fontawesome-fonts-web

# flashfocus
sudo apt -y install python3-xcffib
sudo pip install flashfocus

# vulkan graphics
sudo apt -y install vulkan-loader vulkan-headers vulkan-tools

# wine and dxvk
sudo apt -y install \
    lutris \
    wine \
    wine-dxvk \
    wine-dxvk-dxgi \
    libva-intel-driver

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
    calcurse

# install qogir theme
sudo apt -y install gtk-murrine-engine gtk2-engines
git clone https://github.com/vinceliuice/Qogir-theme.git
sh ./Qogir-theme/install.sh
rm -rf Qogir-theme

git clone https://github.com/vinceliuice/Qogir-icon-theme.git
sh ./Qogir-icon-theme/install.sh
rm -rf Qogir-icon-theme

# password management
sudo apt -y install gnupg
gpg --full-gen-key && \
pass init bundschuh.dennis@gmail.com \
pass insert mail/main

# aws tools
sudo apt -y install \
    aws-tools \
    awscli
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
