#!/bin/sh
#git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# install pathogen plugin manager
mkdir -p ~/.vim/autoload ~/.vim/bundle
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree
git clone git://github.com/tpope/vim-surround.git ~/.vim/bundle/surround 
git clone --depth=1 https://github.com/vim-syntastic/syntastic.git ~./vim/bundle/syntastic

