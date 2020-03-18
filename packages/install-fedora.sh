#!/bin/sh

# update packages to current level
sudo dnf -y update

# xfce4 dm
sudo dnf -y install \
    @xfce-desktop-environment \
    xfce4-vala \
    xfce4-sensors-plugin

# basic packages
sudo dnf -y install \
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
    unrar

# install fonts
sudo dnf -y install \
    terminus-fonts \
    terminus-fonts-console

# podman
sudo dnf -y install \
    podman \
    podman-compose

# password storage
sudo dnf -y install \
    pass \
    passmenu

# python environment
sudo dnf -y install \
    pipenv \
    python3-autopep8 \
    yamllint

# java environment
sudo dnf -y install \
    java-1.8.0-openjdk

# enable rpmfusion repositories
sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# enable tlp power management
sudo dnf -y install tlp tlp-rdw
sudo systemctl enable tlp

# spotify terminal
sudo dnf -y copr enable zeno/spotify-rust
sudo dnf install -y spotifyd spotify-tui
systemctl --user enable --now spotifyd.service

# common media players
sudo dnf -y install \
    vlc \
    vlc-extras

# snap container platform
#sudo dnf -y install snapd

# flatpak container platform
sudo dnf -y install flatpak

# zathura document viewer
sudo dnf install -y \
    zathura \
    zathura-pdf-mupdf

# browser
sudo dnf -y install \
    chromium-browser-privacy \
    firejail surf

# polybar
sudo dnf -y install \
    polybar \
    fontawesome-fonts \
    fontawesome-fonts-web

# flashfocus
sudo dnf -y install python3-xcffib
sudo pip install flashfocus

# screensaver
sudo dnf -y install xfce4-screensaver

# visual studio code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf -y check-update
sudo dnf -y install code

# vulkan graphics
sudo dnf -y install vulkan-loader vulkan-headers vulkan-tools

# wine and dxvk
sudo dnf -y install \
    lutris \
    wine \
    wine-dxvk \
    wine-dxvk-dxgi \
    libva-intel-driver

# hearthstone lutris / wine premise
sudo dnf -y install \
    gnutls \
    gnutls-devel \
    openldap \
    openldap-devel \
    libgpg-error \
    sqlite2.i686 \
    sqlite2.x86_64

# email client
sudo dnf copr enable flatcap/neomutt
sudo dnf -y install \
    neomutt \
    notmuch \
    isync \
    msmtp

# brave browser
sudo sudo dnf -y install dnf-plugins-core
sudo dnf -y config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf -y install brave-browser

# terminal tools and software
sudo dnf -y install \
    w3m \
    w3m-img \
    python3-neovim \
    calcurse

# alacritty terminal emulator
sudo dnf -y copr enable pschyska/alacritty
sudo dnf -y install alacritty

# install qogir theme
sudo dnf -y install gtk-murrine-engine gtk2-engines
git clone https://github.com/vinceliuice/Qogir-theme.git
sh ./Qogir-theme/install.sh
rm -rf Qogir-theme

git clone https://github.com/vinceliuice/Qogir-icon-theme.git
sh ./Qogir-icon-theme/install.sh
rm -rf Qogir-icon-theme

# password management
sudo dnf -y install gnupg
gpg --full-gen-key && \
pass init bundschuh.dennis@gmail.com \
pass insert mail/main

# xfce4-i3-wrkspaces plugin build premise
#sudo dnf install -y \
    #xorg-x11-server-devel \
    #gtk+-devel \
    #gtk2-devel \
    #libxfce4ui-devel \
    #xfce4-panel-devel \
    #json-glib-devel
#mkdir -p ~/storage/packages
#cd ~/storage/packages
#git clone install https://github.com/altdesktop/i3ipc-glib.git
#cd i3ipc-glib
#exec ./autogen.sh --prefix=/usr
#make
#sudo make install
#cd ~/storage/packages
#git clone https://github.com/denesb/xfce4-i3-workspaces-plugin.git
#cd xfce4-i3-workspaces-plugin
#exec ./autogen.sh --prefix=/usr
#make
#sudo make install
#cd ~/

# aws tools
sudo dnf -y install \
    aws-tools \
    awscli
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# kubernetes and minikube
#sudo dnf -y install \
    #@virtualization \
    #kubernetes-client \
    #kubernetes \
    #libvirt-daemon-kvm
#curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
   #&& sudo install minikube-linux-amd64 /usr/local/bin/minikube
#minikube config set vm-driver kvm2
#sudo systemctl enable libvirtd

# helm kubernetes package manager
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh
# !!!! fedora 31 workaround systemd.unified_cgroup_hierarchy=0 intel_iommu=on to
# /etc/default/grub then run grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

# theme hospital foss
# sudo dnf -y install corsix-th corsix-th-data

# julius (caesarIII clone)
# sudo dnf -y install julius

# dwarf fortress
# sudo dnf -y install dwarffortress

# uninstall unnecessary packages
sudo dnf -y remove \
    xscreensaver \
    xscreensaver-base \
    abrt \
    tumbler \
    epiphany-runtime \
    mpv \
    tracker \
    tracker-miners \
    blueberry

# 8bitdo SF30 bluetooth controller settings
sudo wget https://goo.gl/H2SViY -O /etc/udev/rules.d/99-8bitdo-bluetooth-controllers.rules

# use macchanger with netctl
#sudo touch /etc/netctl/interfaces/wlp2s0
#sudo echo "#!/usr/bin/env sh" >> /etc/netctl/interfaces/wlp2s0
#sudo echo "/usr/bin/macchanger -r interface" >> /etc/netctl/interfaces/wlp2s0
#sudo chmod +x /etc/netctl/interfaces/wlp2s0

# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# install steam gaming platform
sudo dnf -y install steam

# parsec streaming service
wget https://tinyurl.com/parsec-fedora ; bash parsec-fedora
rm parsec-fedora

# install snap packages
#snap install \
    #adapta-gtk-snap \
    #gtk-common-themes \
    #gtk2-common-themes \
    #spotify \
    #spotifyd \
    #spt

# install flatpak packages
snap install \
    com.discordapp.Discord \
    com.spotify.Client \
    com.teamspeak.TeamSpeak \
    org.gtk.Gtk3theme.Qogir \
    org.gtk.Gtk3theme.Qogir-win-dark

# additional stuff
unset $SSH_ASKPASS
