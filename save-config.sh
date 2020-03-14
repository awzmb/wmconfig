#!/bin/sh
BASEPATH=./shell
HOMEPATH=~/

for application in "alacritty" "clipit" "i3" "mc" "nvim" "polybar" "vifm" "touchegg" "xfce4" "Code/User" "rofi" "dunst"
do
  mkdir -p ${BASEPATH}/.config/${application}
  cp -r ${HOMEPATH}/.config/${application} ${BASEPATH}/.config/
done


for configfile in ".bashrc" ".mutt" ".vimrc" ".zshrc" ".Xdefaults" ".Xresources" ".mbsyncrc" ".msmtprc"
do
cp -r ${HOMEPATH}/${configfile} ${BASEPATH}/
done
