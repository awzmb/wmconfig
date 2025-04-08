#!/bin/sh

# install pip packages
pip install --user pre-commit --break-system-packages
pip install --user tt-time-tracker --break-system-packages
pip install --user parliament --break-system-packages
pip install --user aws-policy-generator --break-system-packages
pip install --user gcalcli --break-system-packages
pip install --user posting --break-system-packages
pip install --user protonup --break-system-packages
sudo pip install flashfocus --break-system-packages

# flatpak
flatpak install --system -y org.freedesktop.Platform.VAAPI.Intel

# enable user podman.socket
systemctl --user enable --now podman.socket
