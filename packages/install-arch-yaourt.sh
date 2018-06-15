#!/bin/sh
yaourt flashfocus &&
yaourt spotify &&
yaourt intellij &&
yaourt intellij-jdk &&
yaourt adobe-source-code-pro-fonts &&
yaourt hipchat &&
yaourt ultra flat icons &&
yaourt lxdm theme &&
yaourt arc flatabulous &&
yaourt vundle &&
i3lock-fancy

# YouCompleteMe workaround for ncurses5-lib-compat
sudo pacman-key --refresh-keys
gpg --keyserver pgp.mit.edu --recv-keys C52048C0C0748FEE227D47A2702353E0F7E48EDB &&
yaourt ncurses5-compat-libs
