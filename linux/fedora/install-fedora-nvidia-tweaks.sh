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
