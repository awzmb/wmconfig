#!/bin/sh
TMP_DIR=$(mktemp -d)

git clone https://github.com/tkashkin/Adwaita-for-Steam ${TMP_DIR}/theme
cd ${TMP_DIR}/theme
sed -i 's/2E3440FF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/4C566AFF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/353C4AFF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/3B4252FF/242933FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/434954FF/2E3440FF/g' ${TMP_DIR}/theme/adwaita/colorthemes/nord/nord.css
sed -i 's/Cantarell-VF/Terminus/g' ${TMP_DIR}/theme/adwaita/variants/base/_fonts.css
./install.py --color-theme nord --extras login/hide_qr library/hide_whats_new general/no_rounded_corners --target flatpak
