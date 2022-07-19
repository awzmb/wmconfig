#!/bin/sh
# Warning: 'apk add sudo && sudo -lU [name]' before using this script

install_default_packages () {
  # update list and packages
  sudo apk update && sudo apk upgrade

	# basic packages
	sudo apk add \
		vim zsh bash neovim tmux pass \
		openssl curl bat w3m exa zip \
		ctags zsh-vcs python3 ack p7zip \
		coreutils tree ranger nodejs \
		npm yarn curl wget fd fzf openssh \
		coreutils nodejs grep tar openssl \
    ca-certificates ncurses \
    gcompat libuser

	# additional stuff
	sudo apk add \
		terraform ansible aws-cli py3-pip

  # email client
  sudo apk add \
    neomutt calcurse gnupg \
    gnupg-utils pass

	# python packages
	pip install \
		markdown \
		html2text \
		requests \
		beautifulsoup4 \
		pyyaml \
		pyxdg \
		pytz \
		python-dateutil \
		urwid
}

install_desktop_packages () {
	# add user to relevant groups
	sudo adduser $USER input
	sudo adduser $USER video

	# desktop packages
	sudo apk add \
		mesa-dri-gallium ttf-dejavu \
		xfce4-screensaver dbus-x11 faenza-icon-theme \
		xf86-video-vmware xf86-input-mouse \
		xf86-input-keyboard

	# fonts
	sudo apk add \
		unifont nerd-fonts msttcorefonts-installer \
    fontconfig

	# i3 window manager
	sudo apk add \
		i3wm i3lock i3status

	# setup seatd for sway window manager
	sudo apk add seatd
	sudo rc-update add seatd
	sudo rc-service seatd start
  sudo adduser $USER seat

	# setup seatd for sway window manager
	sudo apk add \
    greetd greetd-agreety
	sudo rc-update add greetd
  sudo sed -i -e 's/command.*$/command = \"agreety --cmd \/bin\/zsh\"/g'

	# setup udev
  sudo apk add eudev
  sudo setup-udev

	# sway window manager
	sudo apk add \
		foot \
		dmenu \
		wofi \
		sway \
		swaylock \
		swayidle \
    xwayland

	# additional desktop packages
	sudo apk add \
		redshift scrot grim slurp blueman \
		clipit xdg-utils xdg-desktop-portal \
    xdg-desktop-portal-gtk

  # add users to additional groups
  sudo adduser $USER input
  sudo adduser $USER video
  sudo adduser $USER polkitd
  sudo adduser $USER users

	# audio management
  sudo addgroup $USER audio
	sudo apk add \
    dbus dbus-openrc dbus-x11 \
    alsa-lib alsa-plugins alsa-utils \
    pipewire wireplumber rtkit \
    pipewire-alsa pipewire-pulse \
    pipewire-tools alsa-tools \
    pipewire-spa-bluez pipewire-libs \
    pipewire-media-session \
    pulseaudio pulseaudio-alsa \
    pulseaudio-bluez pavucontrol
  sudo addgroup $USER rtkit
  sudo rc-service dbus start
  sudo rc-update add dbus default
  sudo mkdir -p /etc/pipewire
  sudo cp /usr/share/pipewire/pipewire.conf /etc/pipewire/
  sudo modprobe snd_seq
  sudo echo snd_seq >> /etc/modules
  sudo cp ${PWD}/limits/20-pipewire.conf /etc/security/limits.d/

	# install vnc service
	sudo apk add \
		x11vnc xvfb

	# desktop packages
	sudo apk add \
		faenza-icon-theme \
    arc-darker \
    arc-dark \
    paper-gtk-theme \
    paper-icon-theme

	# browser
	sudo apk add \
    gtk+3.0 \
    chromium

	# networkmanager packags and configuration
	sudo apk add \
    networkmanager \
    network-manager-applet \
    networkmanager-openvpn \
    iwd

  sudo rc-service networkmanager start
  sudo adduser $USER plugdev
sudo tee "/etc/NetworkManager/NetworkManager.conf" > /dev/null <<'EOF'
[main]
dhcp=internal
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=yes
wifi.backend=wpa_supplicant
EOF
  sudo rc-service networking stop
  sudo rc-service wpa_supplicant stop
  sudo rc-service networkmanager restart
  sudo rc-update add networkmanager
  sudo rc-update del networking boot
  sudo rc-update del wpa_supplicant boot
  # allow user to create new wireless networks
  sudo cat linux/alpine/policies/10-org-freedesktop-network-manager-settings.pkla | sed "s/USERNAME/$(whoami)/g" > "/etc/polkit-1/localauthority/50-local.d/10-org-freedesktop-network-manager-settings.pkla"
EOF
  sudo nmtui
}

install_android_packages () {
  # create start script
  mkdir -p ${HOME}/.scripts
	printf '#!/bin/sh\nnohup x11vnc -xkb -nopw -noxrecord -noxfixes -noxdamage -display :0 -loop -shared -forever -bg -auth /var/run/lightdm/root/:0 -rfbport 5900 -o /var/log/vnc.log > /dev/null 2>&1 &' > ${HOME}/.scripts/vncserver-start
	chmod +x ${HOME}/.scripts/vncserver-start
}

install_laptop_packages () {
	# laptop utilities
	sudo apk add \
    pm-utils \
    acpi \
    brightnessctl \
    physlock \
    cpufreqd \
    dhcpcd \
    chrony \
    macchanger \
    wireless-tools \
    iputils \
    powertop \
    light

  # install vpn
  sudo apk add openvpn

  # create tunnel device
  sudo mkdir -p /dev/net
  if [ ! -c /dev/net/tun ]; then
      sudo mknod /dev/net/tun c 10 200
  fi

  # download nordvpn servers
  wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
  unzip ovpn.zip -d /etc/openvpn
  # start nordvpn with sudo openvpn /etc/openvpn/ovpn_udp/us2957.nordvpn.com.udp.ovpn
}

install_boot_packages () {
# TODO: add  video=1920x1080-32 to /etc/default/grub
# TODO: add i915.enable_guc=2 to /etc/default/grub
# TODO: add i915.fastboot=1 to /etc/default/grub
# TODO: add vt.default_red=36,191,163,235,129,180,136,229,191,163,235,129,180,136,229
# TODO: add vt.default_grn=41,97,190,203,161,142,192,233,97,190,203,161,142,192,233
# TODO: add vt.default_blu=51,106,140,139,193,173,208,240,106,140,139,193,173,208,240
  sudo mkdir -p /boot/grub/themes/alpine
  sudo cp ${PWD}/grub/theme.txt /boot/grub/themes/alpine/theme.txt
  sudo sed -i "\$aGRUB_THEME=/boot/grub/themes/alpine/theme.txt" /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg

  # add all revlevant services to boot
  sudo rc-update add acpid
  sudo rc-update add cpufreqd
  sudo rc-update add chrony
  sudo rc-update add wpa-supplicant
  sudo rc-update add dhcpcd
  sudo rc-update add networkmanager

  # suspend on lid close
  sudo mkdir -p /etc/acpi/LID
  sudo tee "/etc/acpi/LID/00000080" > /dev/null <<'EOF'
#!/bin/sh
exec sudo pm-suspend
EOF
  sudo chmod +x /etc/acpi/LID/00000080

  # allow pm-suspend and reboot for user
  sudo tee "/etc/sudoers.d/10-allow-suspend-poweroff-and-reboot" > /dev/null <<'EOF'
%wheel   ALL = NOPASSWD: /usr/sbin/pm-hibernate
%wheel   ALL = NOPASSWD: /usr/sbin/pm-suspend
%wheel   ALL = NOPASSWD: /sbin/poweroff
%wheel   ALL = NOPASSWD: /sbin/reboot
EOF

  # bluetooth
  sudo apk add \
    bluez bluez-alsa-openrc bluez-firmware \
    bluez-zsh-completion bluez-btmgmt
  sudo rc-update add bluetooth
}

# user input
while true; do
    read -p "Do you want to install the basic packages?[y/n] " yn
    case $yn in
        [Yy]* ) install_default_packages; exit 0;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done

# user input
while true; do
    read -p "Do you wish to install a desktop?[y/n] " yn
    case $yn in
        [Yy]* ) install_desktop_packages; exit 0;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done

# user input
while true; do
    read -p "Are you running this on a laptop[y/n] " yn
    case $yn in
        [Yy]* ) install_laptop_packages; exit 0;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done

# user input
while true; do
    read -p "Are you running alpine on android [y/n] " yn
    case $yn in
        [Yy]* ) install_android_packages; exit 0;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done

# boot splash customizations
while true; do
    read -p "Do you want to customize the boot screen [y/n] " yn
    case $yn in
        [Yy]* ) install_boot_packages; exit 0;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
