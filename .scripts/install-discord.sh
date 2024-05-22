#!/bin/sh
BIN_DIR=${HOME}/.bin
INSTALL_DIR=${HOME}/.applications
TMP_DIR=$(mktemp -d)


DISCORD_DL_URL="https://discord.com/api/download?platform=linux&format=tar.gz"
DISCORD_ARCHIVE="discord.tar.gz"
curl -L --output "${TMP_DIR}/${DISCORD_ARCHIVE}" --url ${DISCORD_DL_URL}
#tar xvfz ${TMP_DIR}/${DISCORD_ARCHIVE} -C ${TMP_DIR}
mkdir -p ${INSTALL_DIR}
sudo tar xvfz ${TMP_DIR}/${DISCORD_ARCHIVE} -C ${INSTALL_DIR}
sudo chmod +x ${INSTALL_DIR}/Discord/Discord
sudo chown $(whoami):$(whoami) ${INSTALL_DIR}/Discord/Discord
rm ${BIN_DIR}/discord
ln -s ${INSTALL_DIR}/Discord/Discord ${BIN_DIR}/discord

printf "[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec=/usr/bin/Discord
Icon=/opt/Discord/discord.png
Type=Application
Categories=Network;InstantMessaging;
Path=/usr/bin\n" | sudo tee /usr/share/applications/discord.desktop
