#!/bin/sh

# set hostname
arch-chroot "$workdir" hostnamectl set-hostname 'kodi-box'

# Create kodi user
arch-chroot "$workdir" useradd kodi -m -p '!' -G audio,video,input

# Enable kodi service
arch-chroot "$workdir" systemctl enable kodi.service
