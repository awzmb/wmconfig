#!/bin/sh

# update packages to current level
sudo dnf -y update

ORIGIN_PATH=${pwd}

# basic packages
sudo dnf -y install \
    zsh \
    vim \
    neovim \
    vifm \
    util-linux-user \
    vim \
    calc \
    unrar \
    exa \
    bat \
    jq \
    jd \
    tree \
    ack \
    git \
    fd-find \
    fzf \
    sqlite \
    tmux

# podman container
sudo dnf -y install \
    podman \
    podman-compose \
    containernetworking-plugins

# openvpn connections via nmcli
sudo dnf -y install \
  NetworkManager-openvpn

# password storage
sudo dnf -y install \
    pass

# python environment
sudo dnf -y install \
    pipenv \
    python3-autopep8 \
    python3-pandas \
    python3-pip \
    yamllint

# enable rpmfusion repositories
sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# terminal tools and software
sudo dnf -y install \
  w3m \
  w3m-img \
  python3-neovim \
  calcurse

# install vim-plug plugin manager
# for vim and neovim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# aws tools
sudo dnf -y install \
    aws-tools \
    awscli
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# kubernetes and minikube
#sudo dnf -y install \
    #@virtualization \
    #kubernetes-client \
    #kubernetes \
    #libvirt-daemon-kvm
#curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
   #&& sudo install minikube-linux-amd64 /usr/local/bin/minikube
#minikube config set vm-driver kvm2
#sudo systemctl enable libvirtd

# openvpn
sudo dnf -y install \
  openvpn

# helm kubernetes package manager
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

# vim dependencies
sudo dnf -y install \
  yarnpkg

# password management
sudo dnf -y install gnupg
gpg --full-gen-key && \
pass init bundschuh.dennis@gmail.com \
pass insert mail/main

# additional stuff
unset $SSH_ASKPASS
