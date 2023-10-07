#!/bin/sh
url="https://discord.com/api/download?platform=linux&format=tar.gz"
wget -O- ${url} | sudo tar -xvz  -C /opt
sudo ln -sf /opt/Discord/Discord /usr/bin/Discord

sudo printf "[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec=/usr/bin/Discord
Icon=/opt/Discord/discord.png
Type=Application
Categories=Network;InstantMessaging;
Path=/usr/bin\n" > /usr/share/applications/discord.desktop
