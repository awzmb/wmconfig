#!/bin/sh
sudo apt-get update \
&& sudo apt-get install -y \
i3 \
rxvt-unicode-256-color \
nm-applet \
nitrogen \
compton \
xfce4-power-manager \
autocutsel \
light-themes \
ubuntu-gnome-desktop \
gdm \
pcmanfm \
scrot \
git \
vim \
&& sudo apt-get remove -y unity
