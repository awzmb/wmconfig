#!/bin/sh

ORIGIN_PATH=${pwd}

# enable rpmfusion repositories
rpm-ostree --apply-live install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# install non-free multimedia codecs
#sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
#sudo dnf install rpmfusion-nonfree-release-tainted
#sudo dnf --repo=rpmfusion-nonfree-tainted install "*-firmware"
#sudo dnf -y install intel-media-driver

# layered packages
sudo rpm-ostree -y --apply-live install \
    zsh \
    vim \
    neovim \
    vifm \
    redshift \
    redshift-gtk \
    picom \
    calc \
    unrar \
    eza \
    bat \
    jd \
    ack \
    git \
    fd-find \
    fzf \
    kitty \
    xinput \
    clipit \
    sqlite \
    tmux \
    terminus-fonts \
    terminus-fonts-console \
    terminus-fonts-grub2 \
    unifont \
    unifont-fonts \
    podman-compose \
    containernetworking-plugins \
    pass \
    passmenu \
    oathtool \
    tlp \
    tlp-rdw \
    fontawesome-fonts \
    fontawesome-fonts-web \
    w3m \
    w3m-img \
    python3-neovim \
    calcurse \
    NetworkManager-tui \
    python3-pip \
    python3-xcffib \
    yamllint \
    paper-icon-theme \
    arc-theme \
    libvirt-daemon-kvm \
    driverctl \
    wireguard-tools \
    kubernetes-client \
    gnome-shell-extension-user-theme \
    npm \
    htop \
    distrobox \
    gtk-murrine-engine \
    gtk2-engines \
    ffmpeg-free \
    gstreamer1-vaapi \
    libvdpau-va-gl \
    libva-utils \
    libva-intel-driver \
    libva-vdpau-driver \
    vulkan-tools \
    intel-media-driver

# flathub repositories and premise
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.gnome.Platform
flatpak install --user flathub org.gnome.Sdk
flatpak install --user flathub com.spotify.Client
flatpak install --user flathub com.valvesoftware.Steam
flatpak install --user flathub com.github.Eloston.UngoogledChromium
flatpak install --user org.gtk.Gtk3theme.Qogir-dark
flatpak install -y org.freedesktop.Platform.ffmpeg-full
flatpak install -y org.freedesktop.Platform.GStreamer.gstreamer-vaapi

# install qogir theme
mkdir -p ${HOME}/.themes
git clone https://github.com/vinceliuice/Qogir-theme.git ${HOME}/.themes/qogir-install
./${HOME}/.themes/qogir-install/install.sh
rm -rf ${HOME}/.themes/qogir-install

# give flatpak access to theme directories and set qogir theme
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
sudo flatpak override --env=GTK_THEME=Qogir-Dark
sudo flatpak override --env=ICON_THEME=Paper

# firefox userchrome.css
FIREFOX_PROFILE_DIRECTORY=$(grep 'Path=' ~/.mozilla/firefox/profiles.ini | sed s/^Path=// | grep release)
for profile in ${FIREFOX_PROFILE_DIRECTORY}; do
  git clone https://github.com/awzmb/userchrome $profile/chrome
done

# install vim-plug plugin manager
# for vim and neovim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# enable tlp power management
sudo systemctl enable tlp

# flashfocus
sudo pip install flashfocus

# vulkan graphics
sudo dnf -y install vulkan-loader vulkan-headers vulkan-tools

#sudo dnf -y install \
    #neomutt \
    #notmuch \
    #isync \
    #msmtp

# install mutt-wizard
#git clone https://github.com/LukeSmithxyz/mutt-wizard
#cd mutt-wizard
#sudo make install
#cd ${ORIGIN_PATH}
#rm -rf mutt-wizard

# aws tools
#sudo dnf -y install \
    #aws-tools \
    #awscli
#curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
#sudo mv /tmp/eksctl /usr/local/bin

# kubernetes and minikube
#sudo dnf -y install \
    #@virtualization \
    #kubernetes-client \
    #kubernetes \
#curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
   #&& sudo install minikube-linux-amd64 /usr/local/bin/minikube
#minikube config set vm-driver kvm2
#sudo systemctl enable libvirtd

# helm kubernetes package manager
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

# dwarf fortress
# sudo dnf -y install dwarffortress

# install sway wayland wm
#sudo dnf -y install \
  #foot \
  #dmenu \
  #wofi \
  #fuzzel \
  #sway \
  #swaylock \
  #swayidle \
  #xwayland \
  #xorg-x11-server-Xwayland \
  #i3status \
  #i3status-config-fedora

# install gnome packages
#sudo dnf -y install \
  #gnome-tweaks \
  #gnome-extensions-app \
  #gnome-shell-extension-pop-shell \
  #gnome-shell-extension-pop-shell-shortcut-overrides \
  #gnome-shell-extension-unite \
  #xprop

# install xwayland standalone
#sudo dnf copr enable ofourdan/Xwayland
#sudo dnf upgrade xorg-x11-server-Xwayland
#sudo dnf install xorg-x11-server-Xwayland-devel

# 8bitdo SF30 bluetooth controller settings
sudo wget https://goo.gl/H2SViY -O /etc/udev/rules.d/99-8bitdo-bluetooth-controllers.rules

# use macchanger with netctl
#sudo touch /etc/netctl/interfaces/wlp2s0
#sudo echo "#!/usr/bin/env sh" >> /etc/netctl/interfaces/wlp2s0
#sudo echo "/usr/bin/macchanger -r interface" >> /etc/netctl/interfaces/wlp2s0
#sudo chmod +x /etc/netctl/interfaces/wlp2s0

# install snap packages
#snap install \
    #adapta-gtk-snap \
    #gtk-common-themes \
    #gtk2-common-themes \
    #spotify \
    #spotifyd \
    #spt

# install flashfocus for visual feedback on windows switch
sudo pip install flashfocus

# unclutter (hides mouse when idle)
#sudo dnf -y install unclutter

# install spotify-tui
#sudo dnf -y copr enable szpadel/spotifyd
#sudo dnf -y copr enable atim/spotify-tui
#sudo dnf -y install \
    #spotifyd \
    #spotify-tui

# install asdf for tool management
#git clone https://github.com/asdf-vm/asdf.git ~/.asdf
#cd ~/.asdf
#git checkout "$(git describe --abbrev=0 --tags)"

# change lightdm background
#sed -i 's/^background=.*/background=#242933/g' /etc/lightdm/lightdm-gtk-greeter.conf

# change timezone to europe/berlin
#sudo rm -rf /etc/localtime
#sudo ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# change grub theme
#sudo mkdir -p /boot/grub/themes/fedora
#sudo cp ${PWD}/grub/theme.txt /boot/grub/themes/fedora/theme.txt
#sudo sed -i "\$aGRUB_THEME=/boot/grub/themes/fedora/theme.txt" /etc/default/grub
#sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# set liva driver to iHD for vainfo to work
#if [ ! -n "$(cat /etc/environment | grep LIBVA_DRIVER_NAME)" ]; then
  #echo 'LIBVA_DRIVER_NAME=iHD' | sudo tee -a /etc/environment
#fi

#sudo groupadd shadow-input
#sudo usermod -a -G input $USER
#sudo usermod -a -G shadow-input $USER
#echo "uinput" | sudo tee -a /etc/modules-load.d/uinput.conf
#echo 'KERNEL=="uinput", MODE="0660", GROUP="shadow-input"' | sudo tee -a /etc/udev/rules.d/65-shadow-client.rules

# add options to i915 to enable libva / vainfo
#if [ ! -f "/etc/modprobe.d/i915.conf" ]; then
  #echo "options i915 enable_guc=2" | sudo tee -a /etc/modprobe.d/i915.conf
#fi

# gnome shell settings
# solid color background
gsettings set org.gnome.desktop.background picture-options none
gsettings set org.gnome.desktop.background primary-color '#242933'
gsettings set org.gnome.desktop.background color-shading-type 'solid'
# disable extension validation
gsettings set org.gnome.shell disable-extension-version-validation true
# set pop shell keybinds
#./pop-shell/pop-shell-keybinds.sh

# password management
#sudo dnf -y install gnupg
#gpg --full-gen-key && \
#pass init bundschuh.dennis@gmail.com \
#pass insert mail/main

# additional stuff
unset $SSH_ASKPASS