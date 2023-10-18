#!/bin/sh
sudo dnf -y reinstall gnome-shell
sudo dnf -y install glib2-devel
COLOR="#242933"
GRES="/usr/share/gnome-shell/gnome-shell-theme.gresource"
gresource list "${GRES}" | while read -r RES
do mkdir -p "/tmp/${GRES##*/}.d${RES%/*}"
gresource extract "${GRES}" "${RES}" > "/tmp/${GRES##*/}.d${RES}"
done
tee "/tmp/${GRES##*/}.xml" << EOF > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<gresources><gresource>
$(find "/tmp/${GRES##*/}.d" -type f \
| sed -e "s|^/tmp/${GRES##*/}.d/|<file>|;s|$|</file>|")
</gresource></gresources>
EOF
tee -a "/tmp/${GRES##*/}.d/org/gnome/shell/theme/gnome-shell.css" \
<< EOF > /dev/null
.login-dialog { background-color: ${COLOR}; }
EOF
sudo glib-compile-resources --sourcedir="/tmp/${GRES##*/}.d" \
--target="${GRES}" "/tmp/${GRES##*/}.xml"
rm -f -R "/tmp/${GRES##*/}.d"
sudo systemctl restart gdm.service
