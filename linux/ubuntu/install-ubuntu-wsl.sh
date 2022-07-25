#!/bin/sh

# NOTE: this installer script has been tested only on the
# debian testing branch. some packages might not be available
# on debian stable

# add non-free and contrib to sources.list
sudo dpkg --add-architecture i386

# update packages to current level
sudo apt update && sudo apt upgrade

ORIGIN_PATH=${pwd}
ARCHITECTURE=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')
TMP=$(mktemp -d)
OS=$(uname | tr '[:upper:]' '[:lower:]')
(
)


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

# install yarn (mainly for coc)
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt -y install \
  yarn

# install yarn (mainly for coc)
curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh
sudo bash /tmp/nodesource_setup.sh
sudo apt update
sudo apt -y install \
  nodejs

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

# download minikube binary
sudo wget "https://github.com/kubernetes/minikube/releases/download/v1.26.0/minikube-linux-amd64" -O "/usr/local/bin/minikube" && sudo chmod +x /usr/local/bin/minikube

# start minikube (--force option if you're running this on wsl2)
minikube start --force --driver=podman --memory 2048 --disk-size 4g

# download helm binary
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod +x get_helm.sh && ./get_helm.sh

# add stable helm repository
helm repo add stable https://charts.helm.sh/stable

# install kubectl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubectl

# install krew kubectl package manager
cd $TMP
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-${OS}_${ARCHITECTURE}.tar.gz"
tar zxvf "${KREW}.tar.gz"
./"${}"
export PATH="${PATH}:${HOME}/.krew/bin"

# install krew plugins
kubectl krew install \
  auth-proxy \
  ctx \
  blame \
  ktop \
  ns \
  pod-shell \
  popeye \
  rbac-view \
  rbac-tool

# additional stuff
unset $SSH_ASKPASS
