#!/bin/sh
echo "*********** dmenu height modification"
yay -S dmenu-height &&
echo "*********** flashfocus"
yay -S flashfocus &&
echo "*********** spotify"
yay -S spotify &&
echo "*********** intellij"
yay -S intellij-idea-ce &&
echo "*********** zafiro icons"
yay -S zafiro-icon-theme &&
echo "*********** vundle vim plugin manager"
yay -S vundle-git &&
echo "*********** polybar"
yay -S polybar &&
echo "*********** dmenu netctl"
yay -S netmenu &&
echo "*********** multitouch"
yay -S touchegg &&
echo "*********** ms tt corefonts"
yay -S ttf-ms-fonts &&
echo "*********** brave browser"
yay -S brave-bin
# YouCompleteMe workaround for ncurses5-lib-compat
#sudo pacman-key --refresh-keys
#gpg --keyserver pgp.mit.edu --recv-keys C52048C0C0748FEE227D47A2702353E0F7E48EDB &&
#yay ncurses5-compat-libs
