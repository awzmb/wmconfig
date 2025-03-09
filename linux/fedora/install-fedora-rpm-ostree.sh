#!/bin/sh

ORIGIN_PATH=${pwd}

# enable rpmfusion repositories
rpm-ostree -y --apply-live install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

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

# install tkg kernel for better gaming performance
#rpm-ostree override replace \
  #--experimental \
  #--from repo='copr:copr.fedorainfracloud.org:whitehara:kernel-tkg' \
  #kernel \
  #kernel-core \
  #kernel-modules \
  #kernel-modules-core \
  #kernel-modules-extra

# layered packages
rpm-ostree -y --apply-live --allow-inactive --idempotent install \
    zsh \
    vim \
    neovim \
    vifm \
    gammastep \
    gammastep-indicator \
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
    sqlite \
    tmux \
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
    nautilus \
    gnome-shell-extension-user-theme \
    gnome-tweaks \
    gnome-terminal-nautilus \
    xdg-desktop-portal-gnome \
    npm \
    htop \
    distrobox \
    gtk-murrine-engine \
    gtk2-engines \
    gstreamer1-vaapi \
    libvdpau-va-gl \
    libva-utils \
    libva-vdpau-driver \
    intel-gpu-tools \
    intel-undervolt \
    intel-opencl \
    heif-pixbuf-loader \
    brightnessctl \
    awscli2 \
    aws-tools \
    gdm \
    mpv \
    fuzzel \
    nwg-panel \
    strace \
    openssl \
    alacritty \
    vulkan-loader \
    vulkan-headers \
    vulkan-tools \
    wondershaper \
    inxi \
    msr-tools \
    smbios-utils \
    mangohud \
    vdirsyncer \
    light \
    google-cloud-cli \
    google-cloud-cli-anthos-auth \
    google-cloud-cli-kpt \
    google-cloud-cli-kubectl-oidc \
    google-cloud-cli-skaffold \
    google-cloud-cli-terraform-validator \
    google-cloud-cli-terraform-tools \
    google-cloud-cli-gke-gcloud-auth-plugin \
    google-cloud-sdk-anthos-auth \
    google-cloud-cli-istioctl \
    miller \
    gh \
    git-delta \
    git-lfs \
    git-extras \
    radeontop \
    clipman \
    duf \
    grimshot \
    swaybg \
    swayidle \
    swaylock \
    waybar \
    blueman \
    network-manager-applet \
    wl-clipboard \
    v4l-utils

    #xwaylandvideobridge \
    # hyprland (fedora repo versions are basically
    # unusable with plugins)
    #hyprutils \
    #hyprlock \
    #hypridle \
    #hyprcusor \
    #hyprland-devel \
    #hyprland-protocols-devel \
    #hyprlang-devel \
    #hyprwayland-scanner-devel \
    #hyprsunset \
    #hyprpolkitagent \
    #hyprshot \
    #hyprdim \
    #hyprland \
    #hyprland-devel \
    #xdg-desktop-portal-hyprland \
    #python3-certbot \
    #python3-certbot-apache \
    #python3-certbot-dns-google \
    #python3-certbot-dns-route53 \

# install non-free ffmpeg
#rpm-ostree override remove libavcodec-free libavfilter-free libavformat-free libavutil-free libpostproc-free libswresample-free libswscale-free --install ffmpeg

# install gnome-shell themes
rpm-ostree -y install \
  gnome-shell-theme-flat-remix \
  gnome-shell-extension-common \
  gnome-shell-extension-pop-shell \
  gnome-shell-extension-pop-shell \
  gnome-shell-extension-pop-shell-shortcut-overrides \
  gnome-shell-extension-launch-new-instance

# update firmware
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update

# gaming improvements
# increase maximum number of memory map areas a process may have
echo 'vm.max_map_count = 2147483642' | sudo tee /etc/sysctl.d/11-max-map-count.conf

# install nvidia drivers for egpu
#sudo rpm-ostree install akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda nvtop
#sudo akmods
# install akmods driver package via rpm-ostree (akmods will fail because of missing
# dnf and yum package manager, but the driver will be built)
#sudo rpm-ostree install $(find /var/cache/akmods -type f -name "kmod-*.rpm")

# disable noveau driver to use egpu
#sudo rpm-ostree kargs --append-if-missing=rd.driver.blacklist=nouveau --append-if-missing=modprobe.blacklist=nouveau --append-if-missing=nvidia-drm.modeset=1 initcall_blacklist=simpledrm_platform_driver_init

# activate iommu fgr egpu hotswapping and kvm
#sudo rpm-ostree kargs --append-if-missing=pcie_ports=native pci=assign-busses,nocrs,realloc iommu=on

# flathub repositories and premise
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#flatpak install -y --system org.freedesktop.Platform.ffmpeg-full
#flatpak install -y --system org.freedesktop.Platform.GStreamer.gstreamer-vaapi
#flatpak install -y --system org.freedesktop.Platform.GStreamer.gstreamer-vaapi
#flatpak install -y --system org.gnome.Extensions

flatpak install -y --user flathub com.github.tchx84.Flatseal
flatpak install -y --user flathub com.spotify.Client
flatpak install -y --user flathub org.gtk.Gtk3theme.Qogir-dark
flatpak install -y --user flathub de.shorsh.discord-screenaudio
flatpak install -y --user flathub org.zealdocs.Zeal
flatpak install -y --user flathub org.flameshot.Flameshot
flatpak install -y --user flathub com.brave.Browser
flatpak install -y --user flathub com.parsecgaming.parsec
flatpak install -y --user flathub org.inkscape.Inkscape
flatpak install -y --user flathub org.gimp.GIMP

# use egpu for parsec
flatpak override --user --device=dri --env="DRI_PRIME=1" com.parsecgaming.parsec

# install flatpak steam and proton
# NOTE: flatpak steam has severe performance issues when running cpu-bound games
#flatpak install -y --user flathub com.valvesoftware.Steam
#flatpak install -y --user com.valvesoftware.Steam.CompatibilityTool.Proton
#flatpak install -y --user org.freedesktop.Platform.VulkanLayer.gamescope
#flatpak install -y --user org.freedesktop.Platform.VulkanLayer.MangoHud

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
#printf '[Desktop Entry]\nNoDisplay=true\n' > ~/.local/share/applications/firefox.desktop
#xdg-settings set default-web-browser org.mozilla.firefox.desktop

# TODO: disable sddm and use gdm (if sddm set as display manager)
#sudo systemctl disable sddm.service
#sudo systemctl enable gdm.service

# qogir theme
mkdir -p ${HOME}/.themes
git clone https://github.com/vinceliuice/Qogir-theme.git ${HOME}/.themes/qogir-install
${HOME}/.themes/qogir-install/install.sh
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

# install tmux plugin manager
TMUX_PLUGIN_MANAGER_DIRECTORY=${HOME}/.tmux/plugins/tpm
if [ -d "${TMUX_PLUGIN_MANAGER_DIRECTORY}" ]; then
  cd ${TMUX_PLUGIN_MANAGER_DIRECTORY}; git pull; cd -
else
  git clone https://github.com/tmux-plugins/tpm ${TMUX_PLUGIN_MANAGER_DIRECTORY}
fi

# enable tlp power management
sudo systemctl enable tlp

# install pip packages
pip install --user pre-commit
#pip install --user throttlestop
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

# use macchanger with netctl
#sudo touch /etc/netctl/interfaces/wlp2s0
#sudo echo "#!/usr/bin/env sh" >> /etc/netctl/interfaces/wlp2s0
#sudo echo "/usr/bin/macchanger -r interface" >> /etc/netctl/interfaces/wlp2s0
#sudo chmod +x /etc/netctl/interfaces/wlp2s0

# install flashfocus for visual feedback on windows switch
sudo pip install flashfocus

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
#gpg --full-gen-key && \
#pass init "bundschuh.dennis@gmail.com"

# global git configration
 git config --global user.email "bundschuh.dennis@gmail.com"
 git config --global user.name "Dennis Bundschuh"
 git config --global init.defaultBranch main
 git config --global push.autoSetupRemote true

# install proton-ge
protonup -d "~/.steam/root/compatibilitytools.d/"
protonup

# set default browser
xdg-settings set default-web-browser com.brave.Browser.desktop

# disable systemd-resolved
#sudo systemctl disable --now systemd-resolved.service
#sudo systemctl restart NetworkManager.service

# change primary gpu for gnome (mutter)
#sudo tee /etc/udev/rules.d/61-mutter-primary-gpu.rules << "EOF" > /dev/null
#ENV{DEVNAME}=="/dev/dri/card0", TAG+="mutter-device-preferred-primary"
#EOF

# change default shell to zsh
sudo usermod --shell /bin/zsh $(whoami)

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
