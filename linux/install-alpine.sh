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
		coreutils nodejs grep awk tar

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
  i3wm i3lock i3status
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
