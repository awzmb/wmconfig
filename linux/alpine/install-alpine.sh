#!/bin/bash
# Warning: 'apk add sudo && sudo -lU [name]' before using this script

install_default_packages () {
  # update list and packages
  sudo apk update && sudo apk upgrade

	# basic packages
	sudo apk add \
		vim zsh bash neovim tmux pass \
		openssl curl bat w3m exa zip \
		ctags zsh-vcs python3 ack p7zip \
		coreutils tree ranger nodejs \
		npm yarn curl wget fd fzf openssh \
		coreutils nodejs grep tar openssl \
    ca-certificates ncurses ruby \
    gcompat libuser binutils findutils \
    pciutils util-linux iproute2

	# devops tools
	sudo apk add \
		terraform ansible aws-cli py3-pip \
    pre-commit terragrunt

  # development
	sudo apk add go

  # terraform-docs
  curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz
  tar -xzf terraform-docs.tar.gz
  chmod +x terraform-docs
  mv terraform-docs /usr/local/bin/terraform-docs

  # building
	sudo apk add \
    build-base

  # email client
  sudo apk add \
    neomutt calcurse gnupg \
    gnupg-utils pass

	# python packages
	pip install \
		markdown \
		html2text \
		requests \
		beautifulsoup4 \
		pyyaml \
		pyxdg \
		pytz \
		python-dateutil \
		urwid

  # vim-plug for vim and neovim
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
}

install_desktop_packages () {
	# add user to relevant groups
	sudo adduser $USER input
	sudo adduser $USER video

	# desktop packages
	sudo apk add \
		mesa-dri-gallium ttf-dejavu \
		xfce4-screensaver dbus-x11 faenza-icon-theme \
		xf86-video-vmware xf86-input-mouse \
		xf86-input-keyboard

	# fonts
	sudo apk add \
		unifont nerd-fonts msttcorefonts-installer \
    fontconfig

	# i3 window manager
	sudo apk add \
		i3wm i3lock i3status

	# setup seatd for sway window manager
	sudo apk add seatd
	sudo rc-update add seatd
	sudo rc-service seatd start
  sudo adduser $USER seat

	# setup seatd for sway window manager
	sudo apk add \
    greetd greetd-agreety
	sudo rc-update add greetd
  sudo sed -i -e 's/command.*$/command = \"agreety --cmd \/bin\/zsh\"/g'

	# setup udev
  sudo apk add eudev
  sudo setup-udev

	# sway window manager
	sudo apk add \
		foot \
		dmenu \
		wofi \
		sway \
		swaylock \
		swayidle \
    xwayland \
    waypipe \
    waybar \
    wayland-utils

	# additional desktop packages
	sudo apk add \
		redshift scrot grim slurp blueman \
		clipit xdg-utils xdg-desktop-portal \
    xdg-desktop-portal-gtk

  # add users to additional groups
  sudo adduser $USER input
  sudo adduser $USER video
  sudo adduser $USER polkitd
  sudo adduser $USER users

	# audio management
  sudo addgroup $USER audio
	sudo apk add \
    dbus dbus-openrc dbus-x11 \
    alsa-lib alsa-plugins alsa-utils \
    pipewire wireplumber rtkit \
    pipewire-alsa pipewire-pulse \
    pipewire-tools alsa-tools \
    pipewire-spa-bluez pipewire-libs \
    pipewire-media-session \
    pulseaudio pulseaudio-alsa \
    pulseaudio-bluez pavucontrol
  sudo addgroup $USER rtkit
  sudo rc-service dbus start
  sudo rc-update add dbus default
  sudo mkdir -p /etc/pipewire
  sudo cp /usr/share/pipewire/pipewire.conf /etc/pipewire/
  sudo modprobe snd_seq
  sudo echo snd_seq >> /etc/modules
  sudo cp ${PWD}/limits/20-pipewire.conf /etc/security/limits.d/

	# install vnc service
	sudo apk add \
		x11vnc xvfb

	# desktop packages
	sudo apk add \
		faenza-icon-theme \
    arc-darker \
    arc-dark \
    paper-gtk-theme \
    paper-icon-theme

	# browser
	sudo apk add \
    gtk+3.0 \
    chromium

	# networkmanager packags and configuration
	sudo apk add \
    networkmanager \
    network-manager-applet \
    networkmanager-openvpn \
    iwd

  sudo rc-service networkmanager start
  sudo adduser $USER plugdev
sudo tee "/etc/NetworkManager/NetworkManager.conf" > /dev/null <<'EOF'
[main]
dhcp=internal
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=yes
wifi.backend=wpa_supplicant
EOF
  sudo rc-service networking stop
  sudo rc-service wpa_supplicant stop
  sudo rc-service networkmanager restart
  sudo rc-update add networkmanager
  sudo rc-update del networking boot
  sudo rc-update del wpa_supplicant boot
  # allow user to create new wireless networks
  sudo cat linux/alpine/policies/10-org-freedesktop-network-manager-settings.pkla | sed "s/USERNAME/$(whoami)/g" > "/etc/polkit-1/localauthority/50-local.d/10-org-freedesktop-network-manager-settings.pkla"
EOF
  sudo nmtui
}

install_android_packages () {
  # create start script
  mkdir -p ${HOME}/.scripts
	printf '#!/bin/sh\nnohup x11vnc -xkb -nopw -noxrecord -noxfixes -noxdamage -display :0 -loop -shared -forever -bg -auth /var/run/lightdm/root/:0 -rfbport 5900 -o /var/log/vnc.log > /dev/null 2>&1 &' > ${HOME}/.scripts/vncserver-start
	chmod +x ${HOME}/.scripts/vncserver-start
}

install_laptop_packages () {
	# laptop utilities
	sudo apk add \
    pm-utils \
    acpi \
    brightnessctl \
    physlock \
    cpufreqd \
    dhcpcd \
    chrony \
    macchanger \
    wireless-tools \
    iputils \
    powertop \
    light

  # install vpn
  sudo apk add openvpn

  # create tunnel device
  sudo mkdir -p /dev/net
  if [ ! -c /dev/net/tun ]; then
      sudo mknod /dev/net/tun c 10 200
  fi

  # download nordvpn servers
  wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
  unzip ovpn.zip -d /etc/openvpn
  # start nordvpn with sudo openvpn /etc/openvpn/ovpn_udp/us2957.nordvpn.com.udp.ovpn
}

install_boot_packages () {
# TODO: add  video=1920x1080-32 to /etc/default/grub
# TODO: add i915.enable_guc=2 to /etc/default/grub
# TODO: add i915.fastboot=1 to /etc/default/grub
# TODO: add vt.default_red=36,191,163,235,129,180,136,229,191,163,235,129,180,136,229
# TODO: add vt.default_grn=41,97,190,203,161,142,192,233,97,190,203,161,142,192,233
# TODO: add vt.default_blu=51,106,140,139,193,173,208,240,106,140,139,193,173,208,240
  sudo mkdir -p /boot/grub/themes/alpine
  sudo cp ${PWD}/grub/theme.txt /boot/grub/themes/alpine/theme.txt
  sudo sed -i "\$aGRUB_THEME=/boot/grub/themes/alpine/theme.txt" /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg

  # add all revlevant services to boot
  sudo rc-update add acpid
  sudo rc-update add cpufreqd
  sudo rc-update add chrony
  sudo rc-update add wpa-supplicant
  sudo rc-update add dhcpcd
  sudo rc-update add networkmanager

  # suspend on lid close
  sudo mkdir -p /etc/acpi/LID
  sudo tee "/etc/acpi/LID/00000080" > /dev/null <<'EOF'
#!/bin/sh
exec sudo pm-suspend
EOF
  sudo chmod +x /etc/acpi/LID/00000080

  # allow pm-suspend and reboot for user
  sudo tee "/etc/sudoers.d/10-allow-suspend-poweroff-and-reboot" > /dev/null <<'EOF'
%wheel   ALL = NOPASSWD: /usr/sbin/pm-hibernate
%wheel   ALL = NOPASSWD: /usr/sbin/pm-suspend
%wheel   ALL = NOPASSWD: /sbin/poweroff
%wheel   ALL = NOPASSWD: /sbin/reboot
EOF

  # bluetooth
  sudo apk add \
    bluez bluez-alsa-openrc bluez-firmware \
    bluez-zsh-completion bluez-btmgmt
  sudo rc-update add bluetooth
}

install_dev_packages () {
  # minikube premise
  sudo apk add --no-cache \
    conntrack-tools podman buildah

  # download kubectl binary
  sudo wget "https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kubectl" -O "/usr/local/bin/kubectl"

  # set architecture
	ARCHITECTURE=""
	case $(uname -m) in
			i386)   ARCHITECTURE="386" ;;
			i686)   ARCHITECTURE="386" ;;
			x86_64) ARCHITECTURE="amd64" ;;
			arm)    ARCHITECTURE="aarch64" ;;
	esac

  # download minikube binary
  sudo wget "https://github.com/kubernetes/minikube/releases/download/v1.26.0/minikube-linux-amd64" -O "/usr/local/bin/minikube" && sudo chmod +x /usr/local/bin/minikube

  # create modules directory for minikube
  sudo mkdir -p /lib/modules

  # start minikube (--force option if you're running this on wsl2)
  sudo minikube start --force --driver=podman --memory 2048 --disk-size 4g

  # download helm binary
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod +x get_helm.sh && ./get_helm.sh

  # add stable helm repository
  helm repo add stable https://charts.helm.sh/stable
}


PS3="Select what to install: "

items=("Basic packages" "Desktop packages" "Laptop packages" "Android packages" "Grub modifications" "Dev packages")

select item in "${items[@]}" Quit
do
    case $REPLY in
        1) install_default_packages;;
        2) install_desktop_packages;;
        2) install_laptop_packages;;
        4) install_android_packages;;
        5) install_boot_packages;;
        6) install_dev_packages;;
        $((${#items[@]}+1))) echo "done!"; break;;
        *) echo "unknown choice $REPLY";;
    esac
done
