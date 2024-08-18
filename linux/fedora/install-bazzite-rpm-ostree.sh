#!/bin/sh

ORIGIN_PATH=${pwd}

# enable rpmfusion repositories
#rpm-ostree -y --apply-live install \
    #https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    #https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# enable google-cloud repository
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

# layered packages
rpm-ostree -y --apply-live --allow-inactive --idempotent install \
    zsh \
    neovim \
    vifm \
    gammastep \
    gammastep-indicator \
    calc \
    eza \
    bat \
    jd \
    ack \
    git \
    fd-find \
    kitty \
    xinput \
    clipit \
    terminus-fonts \
    ax86-terminus-ttf-fonts \
    terminus-fonts-console \
    terminus-fonts-grub2 \
    unifont \
    unifont-fonts \
    podman-compose \
    containernetworking-plugins \
    pass \
    passmenu \
    oathtool \
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
    npm \
    htop \
    distrobox \
    gtk-murrine-engine \
    gtk2-engines \
    gstreamer1-vaapi \
    brightnessctl \
    awscli2 \
    aws-tools \
    mpv \
    fuzzel \
    strace \
    openssl \
    alacritty \
    wondershaper \
    msr-tools \
    smbios-utils \
    light \
    google-cloud-cli \
    google-cloud-cli-anthos-auth \
    google-cloud-cli-kpt \
    google-cloud-cli-kubectl-oidc \
    google-cloud-cli-skaffold \
    google-cloud-cli-terraform-validator \
    google-cloud-cli-gke-gcloud-auth-plugin \
    miller \
    gh \
    git-delta \
    git-lfs \
    git-extras \
    fedora-release-sway-atomic \
    sway \
    swaybg \
    waybar \
    blueman \
    rofi \
    dunst \
    network-manager-applet \
    nwg-panel \
    hyprutils \
    hyprland \
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    sunshine \
    xwaylandvideobridge

# install non-free ffmpeg
#rpm-ostree override remove libavcodec-free libavfilter-free libavformat-free libavutil-free libpostproc-free libswresample-free libswscale-free --install ffmpeg

# install gnome-shell themes
#rpm-ostree -y install rpm-ostree install gnome-shell-extension-unite gnome-shell-theme-flat-remix gnome-shell-extension-common gnome-shell-extension-pop-shell gnome-shell-extension-pop-shell gnome-shell-extension-pop-shell-shortcut-overrides

# update firmware
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update

# flathub repositories and premise
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y org.freedesktop.Platform.ffmpeg-full
flatpak install -y org.freedesktop.Platform.GStreamer.gstreamer-vaapi
flatpak install -y org.freedesktop.Platform.GStreamer.gstreamer-vaapi
flatpak install -y org.gnome.Extensions

flatpak install -y --user fedora com.github.tchx84.Flatseal
flatpak install -y --user flathub org.gnome.Platform
flatpak install -y --user flathub org.gnome.Sdk
flatpak install -y --user flathub com.spotify.Client
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
flatpak override --user --filesystem=$HOME/.themes:ro
flatpak override --user --filesystem=$HOME/.icons:ro
#flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
#flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
# use home .mozilla directory to neatlessly be able to swap
# between local and flatpak
flatpak override --user --filesystem=~/.mozilla org.mozilla.firefox
# force the usage of nvidia gpu in steam
#flatpak override --user --env="__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia" com.valvesoftware.Steam

# switch default browser to flatpak firefox and disable the native one
printf '[Desktop Entry]\nNoDisplay=true\n' > ~/.local/share/applications/firefox.desktop
xdg-settings set default-web-browser org.mozilla.firefox.desktop

# TODO: disable sddm and use gdm (if sddm set as display manager)
#sudo systemctl disable sddm.service
#sudo systemctl enable gdm.service


# qogir theme
if [ -d "${HOME}/.themes/Qogir" ]; then
  mkdir -p ${HOME}/.themes
  git clone https://github.com/vinceliuice/Qogir-theme.git ${HOME}/.themes/qogir-install
  ./${HOME}/.themes/qogir-install/install.sh
  rm -rf ${HOME}/.themes/qogir-install
fi

# flatcolor theme (base16)
if [ -d "${HOME}/.themes/FlatColor" ]; then
  git clone https://github.com/jasperro/FlatColor ${HOME}/.themes/FlatColor
fi

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

# install tmux plugin manager
TMUX_PLUGIN_MANAGER_DIRECTORY=${HOME}/.tmux/plugins/tpm
if [ -d "${TMUX_PLUGIN_MANAGER_DIRECTORY}" ]; then
  cd ${TMUX_PLUGIN_MANAGER_DIRECTORY}; git pull; cd -
else
  git clone https://github.com/tmux-plugins/tpm ${TMUX_PLUGIN_MANAGER_DIRECTORY}
fi

# install pip packages
pip install flashfocus
pip install pre-commit
pip install throttlestop
pip install --user tt-time-tracker
pip install --user parliament
pip install --user aws-policy-generator
pip install --user gcalcli
pip install --user posting
pip install --user protonup

# helm kubernetes package manager
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

# 8bitdo SF30 bluetooth controller settings
sudo wget https://goo.gl/H2SViY -O /etc/udev/rules.d/99-8bitdo-bluetooth-controllers.rules

# install flashfocus for visual feedback on windows switch
sudo pip install flashfocus

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
 git config --global user.email "bundschuh.dennis@gmail.com"
 git config --global user.name "Dennis Bundschuh"
 git config --global init.defaultBranch main
 git config --global push.autoSetupRemote true

# additional stuff
unset $SSH_ASKPASS
