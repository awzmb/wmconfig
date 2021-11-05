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
	# desktop packages
	sudo apk add \
		lightdm lightdm-gtk-greeter \
		alacritty alacritty-zsh-completion \
		xfce4-screensaver dbus-x11 faenza-icon-theme\
		xf86-video-vmware xf86-input-mouse \
		xf86-input-keyboard

	# i3 window manager
	sudo apk add \
		i3wm i3lock i3status

	# install vnc service
	sudo apk add \
		x11vnc xvfb

  # create start script
  mkdir -p ${HOME}/.scripts
	printf '#!/bin/sh\nnohup x11vnc -xkb -nopw -noxrecord -noxfixes -noxdamage -display :0 -loop -shared -forever -bg -auth /var/run/lightdm/root/:0 -rfbport 5900 -o /var/log/vnc.log > /dev/null 2>&1 &' > ${HOME}/.scripts/vncserver-start
	chmod +x ${HOME}/.scripts/vncserver-start

	# enable services
	#sudo rc-service lightdm start
	#sudo rc-update add lightdm
	#sudo rc-update add local default
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
