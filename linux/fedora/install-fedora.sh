#!/bin/sh

# update packages to current level
sudo dnf -y update

ORIGIN_PATH=${pwd}

# enable rpmfusion repositories
sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager --enable fedora-cisco-openh264 -y

# install non-free multimedia codecs
sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
sudo dnf install rpmfusion-nonfree-release-tainted
sudo dnf --repo=rpmfusion-nonfree-tainted install "*-firmware"
sudo dnf -y install intel-media-driver

# basic packages
sudo dnf -y install \
    zsh \
    vim \
    neovim \
    vifm \
    util-linux-user \
    rofi \
    gammastep \
    gammastep-indicator \
    light \
    xss-lock \
    pavucontrol \
    feh \
    calc \
    inkscape \
    unrar \
    eza \
    bat \
    jq \
    yq \
    jd \
    tree \
    ack \
    ag \
    ctags \
    git \
    git-delta \
    git-extras \
    fd-find \
    fzf \
    kitty \
    xsetroot \
    clipit \
    sqlite \
    tmux \
    vdirsyncer \
    fd-find \
    miller

# install fonts
sudo dnf -y install \
    terminus-fonts \
    terminus-fonts-console \
    terminus-fonts-grub2 \
    unifont \
    unifont-fonts

# gtk thme changer
sudo dnf -y install \
    lxappearance

# networkmanager stuff
sudo dnf -y install \
    NetworkManager-tui

# podman container
sudo dnf -y install \
    podman \
    podman-compose \
    containernetworking-plugins

# password storage and mfa
sudo dnf -y install \
    pass \
    passmenu \
    oathtool

# python environment
sudo dnf -y install \
    pipenv \
    python3-autopep8 \
    python3-pandas \
    python3-pip \
    yamllint

# java environment
sudo dnf -y install \
    java-1.8.0-openjdk

# enable tlp power management
sudo dnf -y install tlp tlp-rdw
sudo systemctl enable tlp

# autorandr display management
sudo dnf -y copr enable macieks/autorandr
sudo dnf install -y autorandr

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
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y --user com.google.Chrome
flatpak install -y --user org.mozilla.firefox
flatpak install -y --user com.spotify.Client
flatpak install -y --user org.gtk.Gtk3theme.Qogir-dark
flatpak install -y --user com.github.tchx84.Flatseal

# zathura document viewer
sudo dnf install -y \
    zathura \
    zathura-pdf-mupdf

# browser
sudo dnf -y install \
    chromium-browser-privacy \
    firejail surf

# desktop stuff
sudo dnf -y install \
    fontawesome-fonts \
    fontawesome-fonts-web

# flashfocus
sudo dnf -y install python3-xcffib
sudo pip install flashfocus
pip install --user tt-time-tracker

# screensaver
sudo dnf -y install xfce4-screensaver

# vscodium
sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/yum.repos.d/vscodium.repo
sudo dnf -y install codium

# vulkan graphics
sudo dnf -y install vulkan-loader vulkan-headers vulkan-tools

# wine and dxvk
sudo dnf -y install \
    lutris \
    wine \
    wine-dxvk \
    wine-dxvk-dxgi

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
sudo dnf -y copr enable flatcap/neomutt
sudo dnf -y install \
    neomutt \
    notmuch \
    isync \
    msmtp

# install mutt-wizard
git clone https://github.com/LukeSmithxyz/mutt-wizard
cd mutt-wizard
sudo make install
cd ${ORIGIN_PATH}
rm -rf mutt-wizard

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

# install vim-plug plugin manager
# for vim and neovim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# install tmux plugin manager
TMUX_PLUGIN_MANAGER_DIRECTORY=${HOME}/.tmux/plugins/tpm
if [ -d "${TMUX_PLUGIN_MANAGER_DIRECTORY}" ]; then
  cd ${TMUX_PLUGIN_MANAGER_DIRECTORY}; git pull; cd -
else
  git clone https://github.com/tmux-plugins/tpm ${TMUX_PLUGIN_MANAGER_DIRECTORY}
fi

# install themes from repository
sudo dnf -y install \
  gnome-shell-extension-user-theme \
  paper-icon-theme \
  arc-theme

# install qogir theme
sudo dnf -y install \
  gtk-murrine-engine \
  gtk2-engines
git clone https://github.com/vinceliuice/Qogir-theme.git
sh ./Qogir-theme/install.sh
rm -rf Qogir-theme

git clone https://github.com/vinceliuice/Qogir-icon-theme.git
sh ./Qogir-icon-theme/install.sh
rm -rf Qogir-icon-theme

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

# theme hospital foss
# sudo dnf -y install corsix-th corsix-th-data

# julius (caesarIII clone)
# sudo dnf -y install julius

# dwarf fortress
# sudo dnf -y install dwarffortress

# vim dependencies
sudo dnf -y install \
  yarnpkg

# uninstall unnecessary packages
#sudo dnf -y remove \
  #xscreensaver \
  #xscreensaver-base \
  #abrt \
  #tumbler \
  #epiphany-runtime \
  #mpv \
  #tracker \
  #tracker-miners \
  #blueberry

# install sway wayland wm
sudo dnf -y install \
  foot \
  dmenu \
  wofi \
  fuzzel \
  sway \
  swaylock \
  swayidle \
  xwayland \
  xorg-x11-server-Xwayland \
  i3status \
  i3status-config-fedora

# kde plasma
sudo dnf -y install \
  @kde-desktop \
  bismuth

# install gnome packages
sudo dnf -y install \
  gnome-tweaks \
  gnome-extensions-app \
  gnome-shell-extension-pop-shell \
  gnome-shell-extension-pop-shell-shortcut-overrides \
  gnome-shell-extension-unite \
  xprop

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

# install dependencies
sudo dnf -y install pipewire gamemode mesa-va-drivers mesa-dri-drivers mesa-vulkan-drivers

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

# install hsetroot for i3wm solid color background
sudo dnf -y copr enable skidnik/hsetroot
sudo dnf install hsetroot

# install flashfocus for visual feedback
# on windows switch
sudo pip install flashfocus

# unclutter (hides mouse when idle)
sudo dnf -y install unclutter

# install spotify-tui
sudo dnf -y copr enable szpadel/spotifyd
sudo dnf -y copr enable atim/spotify-tui
sudo dnf -y install \
    spotifyd \
    spotify-tui

# install flatpak packages
#snap install \
    #com.discordapp.Discord \
    #com.spotify.Client \
    #com.teamspeak.TeamSpeak \
    #org.gtk.Gtk3theme.Qogir \
    #org.gtk.Gtk3theme.Qogir-win-dark \
    #net.sourceforge.chromium-bsu

# install asdf for tool management
git clone https://github.com/asdf-vm/asdf.git ~/.asdf
cd ~/.asdf
git checkout "$(git describe --abbrev=0 --tags)"

# change lightdm background
sed -i 's/^background=.*/background=#242933/g' /etc/lightdm/lightdm-gtk-greeter.conf

# change timezone to europe/berlin
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# change grub theme
sudo mkdir -p /boot/grub/themes/fedora
sudo cp ${PWD}/grub/theme.txt /boot/grub/themes/fedora/theme.txt
sudo sed -i "\$aGRUB_THEME=/boot/grub/themes/fedora/theme.txt" /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# install iris drivers and libva
sudo dnf -y install \
  libva-utils \
  libva-intel-driver \
  libva-intel-hybrid-driver \
  libvdpau \
  libva-utils \
  libva-vdpau-driver \
  intel-media-driver \
  libvdpau-va-gl \
  ffmpeg

# set liva driver to iHD for vainfo to work
if [ ! -n "$(cat /etc/environment | grep LIBVA_DRIVER_NAME)" ]; then
  echo 'LIBVA_DRIVER_NAME=iHD' | sudo tee -a /etc/environment
fi

sudo groupadd shadow-input
sudo usermod -a -G input $USER
sudo usermod -a -G shadow-input $USER
echo "uinput" | sudo tee -a /etc/modules-load.d/uinput.conf
echo 'KERNEL=="uinput", MODE="0660", GROUP="shadow-input"' | sudo tee -a /etc/udev/rules.d/65-shadow-client.rules

# provide vulkan and metal support
sudo dnf -y install \
  vulkan \
  vulkan-tools

# add options to i915 to enable libva / vainfo
if [ ! -f "/etc/modprobe.d/i915.conf" ]; then
  echo "options i915 enable_guc=2" | sudo tee -a /etc/modprobe.d/i915.conf
fi

# gnome shell settings
# solid color background
gsettings set org.gnome.desktop.background picture-options none
gsettings set org.gnome.desktop.background primary-color '#242933'
gsettings set org.gnome.desktop.background color-shading-type 'solid'
# disable extension validation
gsettings set org.gnome.shell disable-extension-version-validation true
# set pop shell keybinds
./pop-shell/pop-shell-keybinds.sh

# firefox configuration
FIREFOX_PROFILE_DIRECTORY=$(grep 'Path=' ~/.mozilla/firefox/profiles.ini | sed s/^Path=// | grep release)
for profile in ${FIREFOX_PROFILE_DIRECTORY}; do
  git clone https://github.com/awzmb/userchrome $profile/chrome
done

# flathub repositories and premise
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.gnome.Platform//46
flatpak install --user flathub org.gnome.Sdk//46
# install citrix workspace
# git clone https://github.com/dcloud-ca/ca.dcloud.ICAClient ~/workspace/flathub-citrix-reciever
# cd ~/workspace/flathub-citrix-reciever
# flatpak-builder --user --install --force-clean icaclient ca.dcloud.ICAClient.yml

# password management
#sudo dnf -y install gnupg
#gpg --full-gen-key && \
#pass init bundschuh.dennis@gmail.com \
#pass insert mail/main

# librewolf (custom firefox)
sudo dnf config-manager --add-repo https://rpm.librewolf.net/librewolf-repo.repo
sudo dnf -y install librewolf

# install driverctl for gpu passthrough
sudo dnf -y install driverctl

# wireguard tools
sudo dnf -y install wireguard-tools

# drawing architecture diagrams
sudo dnf -y install plantuml
sudo npm install -g node-plantuml

# google cloud cli
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
sudo dnf -y install \
  google-cloud-cli \
  google-cloud-cli-gke-gcloud-auth-plugin \
  google-cloud-cli-anthoscli \
  google-cloud-cli-kpt

# github cli
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install gh

# set bredr bluetooth controller mode to make bluetooth
# headsets work properly
sudo sed -i 's/.*ControllerMode.*/ControllerMode=dual/g' /etc/bluetooth/main.conf
sudo systemctl restart bluetooth.service

# disable those nasty bluetooth headset hfp modes
WIREPLUMBER_CONFIG_DIR=${HOME}/.config/wireplumber/wireplumber.conf.d/
mkdir -p ${WIREPLUMBER_CONFIG_DIR}
tee -a ${WIREPLUMBER_CONFIG_DIR}/80-bluetooth-properties.conf << EOM
wireplumber.settings = {
  bluetooth.autoswitch-to-headset-profile = false
}

monitor.bluez.properties = {
  bluez5.roles = [ a2dp_sink a2dp_sink_sbc_xq a2dp_sink_sbc a2dp_source ]
}
EOM
systemctl --user restart wireplumber
systemctl --user restart pipewire

# additional stuff
unset $SSH_ASKPASS
