#!/bin/sh

# update packages to current level
sudo dnf -y update

# nvidia
sudo dnf -y install kernel-devel akmod-nvidia nvidia-vaapi-driver xorg-x11-drv-nvidia-cuda-libs

# enable asus-linux repo
sudo dnf -y copr enable lukenukem/asus-linux
sudo dnf install asusctl supergfxctl
sudo dnf update --refresh
sudo systemctl enable supergfxd.service
sudo dnf install asusctl-rog-gui

# enable nvidia power
sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service

# enable nvidia-docker2 repo
curl -s -L https://nvidia.github.io/nvidia-docker/centos8/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo dnf update --refresh
sudo dnf -y install nvidia-container-toolkit

# configure docker runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
