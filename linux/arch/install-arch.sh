#!/bin/sh
sudo pacman -Sy \
  xorg xorg-xinit xterm i3 alacritty dmenu compton \
  surf \
  jdk8-openjdk \
  scrot \
  firefox \
  blueman \
  podman podman-compose ansible \
  pcmanfm \
  pass \
  lxsession lxappearance \
  nitrogen \
  xfce4-settings xfce4-power-manager \
  zsh zsh-syntax-highlighting zsh-completions \
  neovim python-pynvim \
  pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulsemixer pavucontrol &&
sudo pacman -S --needed \
  base-devel \
  git \
  wget \
  lsb-release \
  evince \
  ttf-hack \
  ttf-opensans \
  gnu-free-fonts \
  terminus-font \
  neomutt \
  notmuch \
  isync \
  msmtp \
  gnupg \
  vifm \
  mpg123 \
  tlp \
  calcurse \
  libcaca \
  w3m \
  python-pylint python-markdown python-html2text python-requests \
  gvfs \
  xautolock \
  redshift \
  dunst \
  tmux \
  inkscape \
  optipng \
  adapta-gtk-theme \
  adapta-kde \
  pygtk \
  python2-dbus \
  python-pyopencl \
  xf86-video-intel lib32-freetype2 xf86-input-synaptics \
  powertop \
  firejail \
  acpi \
  xss-lock \
  bind-tools \
  macchanger \
  bluez bluez-utils bluez-tools bluez-plugins bluez-cups \
  vlc \
  texlive-most ghostscript \
  wine wine-mono winetricks lutris \
  lib32-gnutls lib32-libldap lib32-libgpg-error lib32-sqlite lib32-libpulse \
  vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader \
  desktop-file-utils \
  libvdpau-va-gl libva-utils libva-intel-driver
#  && \
#gpg --full-gen-key && \
#pass init dennis.bundschuh@ancud.de \
#pass insert mail/main

# install vim-plug plugin manager
# for vim and neovim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# use macchanger with netctl
sudo touch /etc/netctl/interfaces/wlp2s0
sudo echo "#!/usr/bin/env sh" >> /etc/netctl/interfaces/wlp2s0
sudo echo "/usr/bin/macchanger -r interface" >> /etc/netctl/interfaces/wlp2s0
sudo chmod +x /etc/netctl/interfaces/wlp2s0

# 8bitdo SF30 bluetooth controller settings
sudo wget https://goo.gl/H2SViY -O /etc/udev/rules.d/99-8bitdo-bluetooth-controllers.rules ;

# ruby terminal jira cleint
#sudo gem install terjira
#gem install terjira --user-install

# disable touchpad one tap click and revert scroll direction
#synclient VertScrollDelta=-79
#synclient TapButton1=0

sudo cat <<EOF > /etc/X11/xorg.conf.d/70-synaptics.conf
Section "InputClass"
    Identifier "touchpad"
    Driver "synaptics"
    MatchIsTouchpad "on"
        Option "TapButton1" "0"
#        Option "TapButton1" "1"
        Option "TapButton2" "3"
        Option "TapButton3" "2"
        Option "VertEdgeScroll" "on"
        Option "VertTwoFingerScroll" "on"
    	Option "VertScrollDelta=-79"
        Option "HorizEdgeScroll" "on"
        Option "HorizTwoFingerScroll" "on"
        Option "CircularScrolling" "on"
        Option "CircScrollTrigger" "2"
        Option "EmulateTwoFingerMinZ" "40"
        Option "EmulateTwoFingerMinW" "8"
        Option "CoastingSpeed" "0"
        Option "FingerLow" "30"
        Option "FingerHigh" "50"
        Option "MaxTapTime" "125"
EndSection
EOF
