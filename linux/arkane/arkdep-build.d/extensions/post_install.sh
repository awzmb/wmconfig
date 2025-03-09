#!/bin/sh

# reference custom sway startup script in systemd unit
sed -i -e 's|Exec=.*|Exec=/usr/local/bin/sway-egpu|g' /usr/share/wayland-sessions/sway.desktop
