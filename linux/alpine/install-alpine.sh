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
    ca-certificates

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
		greetd mesa-dri-gallium ttf-dejavu \
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
		clipit

  # add users to additional groups
  sudo adduser $USER input
  sudo adduser $USER video
  sudo adduser $USER polkitd
  sudo adduser $USER users

	# audio management
  sudo addgroup $USER audio
	sudo apk add \
    dbus dbus-openrc dbus-x11 \
    pipewire wireplumber rtkit \
    pipewire-alsa pipewire-pulse \
    pipewire-tools alsa-tools \
    alsa-lib alsa-plugins alsa-utils \
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
