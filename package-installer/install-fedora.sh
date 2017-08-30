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
# Albion Online
qt5-qtwebengine \
qt5-qtwebchannel \
qt5-qtsensors \
qt5-qtlocation \
ffmpeg \
gstreamer1-plugins-ugly \
&& sudo cp clipboard /usr/lib64/urxvt/perl/ \
&& git clone https://github.com/vinceliuice/vimix-gtk-themes.git \
&& sudo ./vimix-gtk-themes/Vimix-installer.sh \
&& rm -rf vimix-gtk-themes \
# Arc theme
&& sudo dnf config-manager --add-repo http://download.opensuse.org/repositories/home:Horst3180/Fedora_25/home:Horst3180.repo \
&& sudo dnf install-y arc-theme
# Screencasting via peek
&& sudo dnf config-manager --add-repo http://download.opensuse.org/repositories/home:/Bajoja/Fedora_25/home:Bajoja.repo \
&& sudo dnf install -y peek