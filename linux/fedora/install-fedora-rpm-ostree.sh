#!/bin/sh

ORIGIN_PATH=${pwd}

# enable rpmfusion repositories
rpm-ostree --apply-live install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

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
    gnome-tweaks \
    xdg-desktop-portal-gnome \
    npm \
    htop \
    distrobox \
    gtk-murrine-engine \
    gtk2-engines \
    gstreamer1-vaapi \
    libvdpau-va-gl \
    libva-utils \
    libva-intel-driver \
    libva-vdpau-driver \
    intel-gpu-tools \
    intel-media-driver \
    intel-undervolt \
    intel-opencl \
    heif-pixbuf-loader \
    libheif-freeworld \
    libheif-tools \
    pipewire-codec-aptx \
    #ffmpeg-free \
    #tuigreet \
    vulkan-tools \
    helm \
    brightnessctl \
    awscli2 \
    aws-tools \
    aws-docs \
    gdm \
    mpv \
    fuzzel \
    hyprland \
    strace \
    openssl

# install non-free ffmpeg
rpm-ostree override remove libavcodec-free libavfilter-free libavformat-free libavutil-free libpostproc-free libswresample-free libswscale-free --install ffmpeg

# update firmware
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update

# flathub repositories and premise
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y org.freedesktop.Platform.ffmpeg-full
flatpak install -y org.freedesktop.Platform.GStreamer.gstreamer-vaapi
flatpak install -y org.freedesktop.Platform.GStreamer.gstreamer-vaapi

flatpak install -y --user fedora com.github.tchx84.Flatseal
flatpak install -y --user flathub org.gnome.Platform
flatpak install -y --user flathub org.gnome.Sdk
flatpak install -y --user flathub com.spotify.Client
flatpak install -y --user flathub com.valvesoftware.Steam
flatpak install -y --user flathub com.github.Eloston.UngoogledChromium
flatpak install -y --user flathub org.gtk.Gtk3theme.Qogir-dark
flatpak install -y --user flathub de.shorsh.discord-screenaudio
flatpak install -y --user flathub org.mozilla.firefox
flatpak install -y --user flathub io.gitlab.librewolf-community
flatpak install -y --user flathub com.usebottles.bottles
flatpak install -y --user flathub org.zealdocs.Zeal
flatpak install -y --user flathub org.flameshot.Flameshot
flatpak install -y --user flathub net.lutris.Lutris
flatpak install -y --user flathub com.google.Chrome
flatpak install -y --user org.inkscape.Inkscape
flatpak install -y --user org.gimp.GIMP

# allow access to local themes and gtk settings
sudo flatpak override --filesystem=$HOME/.themes:ro
sudo flatpak override --filesystem=$HOME/.icons:ro
flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
# use home .mozilla directory to neatlessly be able to swap
# between local and flatpak
flatpak override --user --filesystem=~/.mozilla org.mozilla.firefox

# TODO: disable sddm and use gdm (if sddm set as display manager)

# qogir theme
mkdir -p ${HOME}/.themes
git clone https://github.com/vinceliuice/Qogir-theme.git ${HOME}/.themes/qogir-install
./${HOME}/.themes/qogir-install/install.sh
rm -rf ${HOME}/.themes/qogir-install

# flatcolor theme (base16)
git clone https://github.com/jasperro/FlatColor ${HOME}/.themes/FlatColor
# TODO: inject nord theme from https://github.com/tinted-theming/base16-gtk-flatcolor/blob/main/gtk-2/base16-nord-gtkrc

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

# install pip packages
sudo pip install flashfocus
pip install tt-time-tracker
pip install parliament
pip install aws-policy-generator
pip install pre-commit
pip install gcalcli

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

# helm kubernetes package manager
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

# dwarf fortress
# sudo dnf -y install dwarffortress

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
#pass init "dennis.bundschuh@metamorphant.de" \
#pass insert mail/main

# global git configration
 git config --global user.email "dennis.bundschuh@metamorphant.de"
 git config --global user.name "Dennis Bundschuh"
 git config --global init.defaultBranch main
 git config --global push.autoSetupRemote true

# additional stuff
unset $SSH_ASKPASS
