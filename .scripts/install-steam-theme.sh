#!/bin/sh
TMP_DIR=$(mktemp -d)

echo ${TMP_DIR}
git clone https://github.com/tkashkin/Adwaita-for-Steam ${TMP_DIR}/theme
cd ${TMP_DIR}/theme
sed -i 's/2E3440FF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/Cantarell-VF/Terminus/g' ${TMP_DIR}/theme/adwaita/variants/base/_fonts.css
./install.py --color-theme nord --extras login/hide_qr library/hide_whats_new general/no_rounded_corners --target flatpak
