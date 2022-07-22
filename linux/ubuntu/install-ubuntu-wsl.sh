#!/bin/sh

# NOTE: this installer script has been tested only on the
# debian testing branch. some packages might not be available
# on debian stable

# add non-free and contrib to sources.list
sudo dpkg --add-architecture i386

# update packages to current level
sudo apt update && sudo apt upgrade

ORIGIN_PATH=${pwd}

# basic packages
sudo apt -y install \
  zsh \
  vim \
  neovim \
  vifm \
  vim \
  neovim \
  calc \
  unrar \
  bat \
  jq \
  tree \
  ack \
  git \
  fd-find \
  fzf \
  curl \
  wget \
  tmux \
  ranger \
  gnupg2

# install node and yarn (mainly for coc)
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt -y install \
  nodejs \
  yarn

# podman (docker replacement)
VERSION_ID=$(cat /etc/os-release | grep "VERSION_ID" | sed 's/.*=//g' | tr -d \")
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | sudo apt-key add -
sudo apt -y update
sudo apt -y install podman

# additional terminal tools
sudo apt -y install \
  w3m \
  w3m-img \
  python3-neovim \
  calcurse \
  newsboat \
  neofetch

# download kubectl binary
sudo wget "https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kubectl" -O "/usr/local/bin/kubectl"

# set architecture
ARCHITECTURE=""
case $(uname -m) in
    i386)   ARCHITECTURE="386" ;;
    i686)   ARCHITECTURE="386" ;;
    x86_64) ARCHITECTURE="amd64" ;;
    arm)    ARCHITECTURE="aarch64" ;;
esac

# download minikube binary
sudo wget "https://github.com/kubernetes/minikube/releases/download/v1.26.0/minikube-linux-amd64" -O "/usr/local/bin/minikube" && sudo chmod +x /usr/local/bin/minikube

# start minikube (--force option if you're running this on wsl2)
minikube start --force --driver=podman --memory 2048 --disk-size 4g

# download helm binary
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod +x get_helm.sh && ./get_helm.sh

# add stable helm repository
helm repo add stable https://charts.helm.sh/stable

# additional stuff
unset $SSH_ASKPASS
