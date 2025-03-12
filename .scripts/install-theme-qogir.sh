#!/bin/sh

# qogir theme
mkdir -p ${HOME}/.themes
git clone https://github.com/vinceliuice/Qogir-theme.git ${HOME}/.themes/qogir-install
${HOME}/.themes/qogir-install/install.sh
rm -rf ${HOME}/.themes/qogir-install
