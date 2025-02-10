#!/bin/sh

ORIGIN_PATH=${pwd}

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
rpm-ostree -y --idempotent install \
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
    python3-xcffib \
    yamllint \
    paper-icon-theme \
    arc-theme \
    libvirt-daemon-kvm \
    npm \
    htop \
    gtk-murrine-engine \
    gtk2-engines \
    brightnessctl \
    awscli2 \
    aws-tools \
    mpv \
    fuzzel \
    alacritty \
    wondershaper \
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
    sway \
    swaybg \
    waybar \
    blueman \
    rofi \
    dunst \
    clipman \
    network-manager-applet \
    hyprutils \
    hyprland \
    hyprlock \
    hypridle \
    hyprutils \
    xdg-desktop-portal-hyprland \
    pavucontrol \
    grimshot

# install gnome-shell themes
rpm-ostree -y install \
    gnome-shell-extension-unite \
    gnome-shell-theme-flat-remix \
    gnome-shell-extension-pop-shell \
    gnome-shell-extension-pop-shell-shortcut-overrides

# update firmware
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update

# flathub repositories and premise
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y --system org.gnome.Extensions
flatpak install -y --user fedora com.github.tchx84.Flatseal
flatpak install -y --user flathub com.spotify.Client
flatpak install -y --user flathub org.gtk.Gtk3theme.Qogir-dark
flatpak install -y --user flathub org.zealdocs.Zeal
flatpak install -y --user flathub org.flameshot.Flameshot
flatpak install -y --user flathub com.google.Chrome
flatpak install -y --user flathub com.brave.Browser
flatpak install -y --user flathub dev.vencord.Vesktop
flatpak install -y --user fedora org.inkscape.Inkscape
flatpak install -y --user fedora org.gimp.GIMP

# qogir theme
if [ -d "${HOME}/.themes/Qogir" ]; then
  mkdir -p ${HOME}/.themes
  git clone https://github.com/vinceliuice/Qogir-theme.git ${HOME}/.themes/qogir-install
  ${HOME}/.themes/qogir-install/install.sh
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
pip install pre-commit
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

# change default shell to zsh
sudo usermod --shell /bin/zsh $(whoami)

# set default browser
xdg-settings set default-web-browser com.brave.Browser.desktop

# set bredr bluetooth controller mode to make bluetooth
# headsets work properly
sudo sed -i 's/.*ControllerMode.*/ControllerMode=bredr/g' /etc/bluetooth/main.conf
sudo systemctl restart bluetooth.service

# additional stuff
unset $SSH_ASKPASS
