#!/bin/sh
# Warning: 'apk add sudo && sudo -lU [name]' before using this script

install_default_packages () {
  # update list and packages
  sudo apk update && sudo apk upgrade

	# basic packages
	pkg install \
		vim zsh bash neovim tmux pass \
		openssl curl bat w3m exa zip \
		ctags python3 p7zip \
		coreutils tree ranger nodejs \
		yarn curl wget fd fzf openssh \
		coreutils nodejs grep tar openssl \
    ca-certificates ncurses

	# coc.nvim packages
  pkg install \
    nodejs yarn
	# additional stuff
	pkg install \
		terraform

  # email client
  pkg install \
    neomutt calcurse gnupg pass

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

  # vim-plug for vim and neovim
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
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
