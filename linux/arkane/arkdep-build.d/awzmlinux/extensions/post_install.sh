#!/bin/sh

# reference custom sway startup script in systemd unit
sed -i -e 's|Exec=.*|Exec=/usr/local/bin/sway-egpu|g' /usr/share/wayland-sessions/sway.desktop

# remove fallback hyprland configuration
rm -f /usr/share/hypr/hyprland.conf

# workaround for https://www.reddit.com/r/archlinux/comments/1ja6y69/it_looks_like_linuxfirmware_20250311b69d4b742_has/
#TMP_DIR=$(mktemp -d)
#curl -L https://archive.archlinux.org/packages/l/linux-firmware/linux-firmware-20250210.5bc5868b-1-any.pkg.tar.zst -o $TMP_DIR/linux-firmware-20250210.5bc5868b-1-any.pkg.tar.zst
#pacman -U --noconfirm $TMP_DIR/linux-firmware-20250210.5bc5868b-1-any.pkg.tar.zst
#rm -rf $TMP_DIR

# set hostname
hostnamectl set-hostname 'L0223-1024'

# enable seatd and keyd
systemctl enable seatd
systemctl enable keyd
