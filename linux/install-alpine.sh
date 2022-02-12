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
		sway \
		foot \
		dmenu \
		swaylock \
		wofi \
		swaylock \
		swayidle

	# additional desktop packages
	sudo apk add \
		redshift scrot grim slurp blueman \
		clipit pulseaudio pulseaudio-alsa

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


  # create start script
  mkdir -p ${HOME}/.scripts
	printf '#!/bin/sh\nnohup x11vnc -xkb -nopw -noxrecord -noxfixes -noxdamage -display :0 -loop -shared -forever -bg -auth /var/run/lightdm/root/:0 -rfbport 5900 -o /var/log/vnc.log > /dev/null 2>&1 &' > ${HOME}/.scripts/vncserver-start
	chmod +x ${HOME}/.scripts/vncserver-start
}

# user input
while true; do
    read -p "Do you wish to install a desktop?" yn
    case $yn in
        [Yy]* ) install_default_packages; install_desktop_packages; exit 0;;
        [Nn]* ) install_default_packages; exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
