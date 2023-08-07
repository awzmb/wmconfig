#!/bin/sh
# Warning: 'apk add sudo && sudo -lU [name]' before using this script

install_default_packages () {
  # update list and packages
  sudo apk update && sudo apk upgrade

	# basic packages
	pkg install -y \
		vim zsh bash neovim tmux pass \
		openssl curl bat w3m exa zip \
		ctags python3 p7zip \
		coreutils tree ranger nodejs \
		yarn curl wget fd fzf openssh \
		coreutils nodejs grep tar openssl \
    ca-certificates ncurses perl \
    binutils ruby ldd ctags ncurses-utils \
    jq

  # awscli
  #pkg install -y \
    #git python rust build-essential

	# coc.nvim packages
  pkg install -y \
    nodejs yarn

  # email client
  pkg install -y \
    neomutt calcurse gnupg pass

	# python packages
	pip install -y \
		markdown \
		html2text \
		requests \
		beautifulsoup4 \
		pyyaml \
		pyxdg \
		pytz \
		python-dateutil \
		urwid \
    jedi

  # vim-plug for vim and neovim
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
}

install_default_packages
