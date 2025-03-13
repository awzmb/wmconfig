#!/bin/sh

# reference custom sway startup script in systemd unit
sed -i -e 's|Exec=.*|Exec=/usr/local/bin/sway-egpu|g' /usr/share/wayland-sessions/sway.desktop

# remove fallback hyprland configuration
rm -f /usr/share/hypr/hyprland.conf
