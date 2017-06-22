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
gtk-murrine-engine \
gtk2-engines \
xclip \
vim \
java-1.8.0-openjdk-devel \
glib2-devel \
&& sudo cp clipboard /usr/lib64/urxvt/perl/ \
&& git clone https://github.com/vinceliuice/vimix-gtk-themes.git \
&& sudo ./vimix-gtk-themes/Vimix-installer.sh \
&& rm -rf vimix-gtk-themes
