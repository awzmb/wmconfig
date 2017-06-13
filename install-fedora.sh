#!/bin/sh
sudo dnf update \
&& sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
&& sudo dnf install -y \
i3 \
rxvt-unicode-256color \
nitrogen \
compton \
xfce4-power-manager \
light-theme-gnome \
network-manager-applet \
pcmanfm \
scrot \
git \
arandr \
tlp \
lxappearance \
numix-gtk-theme \
numix-icon-theme \
numix-icon-theme-circle \
vim
