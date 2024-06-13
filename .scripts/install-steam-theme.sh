#!/bin/sh
TMP_DIR=$(mktemp -d)

git clone https://github.com/tkashkin/Adwaita-for-Steam ${TMP_DIR}/theme
cd ${TMP_DIR}/theme
#sed -i 's/2E3440FF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
#sed -i 's/4C566AFF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
#sed -i 's/353C4AFF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
#sed -i 's/3B4252FF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
#sed -i 's/434954FF/2E3440FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/46, 52, 64/36, 41, 51/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/76, 86, 106/36, 41, 51/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/53, 60, 74/36, 41, 51/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/59, 66, 82/36, 41, 51/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/46, 52, 64/36, 41, 51/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/0.36/0/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/Cantarell-VF/Terminus/g' ${TMP_DIR}/theme/adwaita/css/_root/text.css

FLATPAK_DIRECTORY="${HOME}/.var/app/com.valvesoftware.Steam/.steam/steam"
REGULAR_DIRECTORY="${HOME}/.steam/steam"

if [ -d "$FLATPAK_DIRECTORY" ]; then
  ./install.py --color-theme nord --extras login/hide_qr library/hide_whats_new general/no_rounded_corners --target flatpak
elif [ -d "$REGULAR_DIRECTORY" ]; then
  ./install.py --color-theme nord --extras login/hide_qr library/hide_whats_new general/no_rounded_corners
else
  echo "${FLATPAK_DIRECTORY} not found."
  echo "${REGULAR_DIRECTORY} not found."
  echo "Install and run steam at least once before using this script."
fi
