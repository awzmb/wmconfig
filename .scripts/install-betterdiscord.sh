#!/bin/sh
APPIMAGE_DIRECTORY=${HOME}/.appimage
mkdir -p ${APPIMAGE_DIRECTORY}

BETTERDISCORD_VERSION=$(curl -s https://api.github.com/repos/BetterDiscord/installer/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
curl -L --output "${APPIMAGE_DIRECTORY}/betterdiscord.AppImage" --url "https://github.com/BetterDiscord/Installer/releases/download/v${BETTERDISCORD_VERSION}/BetterDiscord-Linux.AppImage"
chmod +x ${APPIMAGE_DIRECTORY}/betterdiscord.AppImage
