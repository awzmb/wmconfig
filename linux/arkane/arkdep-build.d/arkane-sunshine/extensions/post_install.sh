#!/bin/bash

# remove fallback hyprland configuration
arch-chroot "$workdir" rm -f /usr/share/hypr/hyprland.conf

# set hostname
arch-chroot "$workdir" hostnamectl set-hostname 'bsunshine'

# Install AUR packages
# Set list of AUR packages to install
# aur_packages=('yay-bin' 'paru-bin')
#
# # Install build dependencies
# printf '\e[1;32m-->\e[0m\e[1m Installing build dependencies\e[0m\n'
# arch-chroot "$workdir" pacman -Sy --noconfirm --needed base-devel git
#
# # Create temporary unprivileged user, required for fakeroot
# printf '\e[1;32m-->\e[0m\e[1m Creating temporary user\e[0m\n'
# arch-chroot "$workdir" useradd aur -m -p '!'
#
# # Allow 'aur' to use sudo without password
# printf '\e[1;32m-->\e[0m\e[1m Allowing aur user passwordless sudo\e[0m\n'
# arch-chroot "$workdir" bash -c "echo 'aur ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/aur"
#
# # Build and install packages from pkgbuild
# printf '\e[1;32m-->\e[0m\e[1m Building and installing local packages\e[0m\n'
# pkgbuild_dir="arkdep-build.d/awzmlinux/pkgbuild"
# for pkg in "$pkgbuild_dir"/*; do
#   if [ -d "$pkg" ]; then
#     pkg_name=$(basename "$pkg")
#     printf "\e[1;32m-->\e[0m\e[1m Building $pkg_name\e[0m\n"
#     cp -r "$pkg" "$workdir/home/aur/"
#     arch-chroot "$workdir" chown -R aur:aur "/home/aur/$pkg_name"
#     arch-chroot -u aur:aur "$workdir" bash -c "cd /home/aur/$pkg_name && makepkg -si --noconfirm"
#   fi
# done
#
# # Install yay manually first (because we need it to install others)
# printf '\e[1;32m-->\e[0m\e[1m Bootstrapping yay-bin\e[0m\n'
# arch-chroot -u aur:aur "$workdir" bash -c "
#   cd /home/aur &&
#   git clone https://aur.archlinux.org/yay-bin.git &&
#   cd yay-bin &&
#   makepkg -si --noconfirm
# "
#
# # Install AUR packages using yay
# for package in "${aur_packages[@]}"; do
#     printf "\e[1;32m-->\e[0m\e[1m Installing $package using yay\e[0m\n"
#     arch-chroot -u aur:aur "$workdir" bash -c "yay -S --noconfirm $package"
# done
#
# # Cleanup sudoers file
# printf '\e[1;32m-->\e[0m\e[1m Removing temporary sudoers rule\e[0m\n'
# arch-chroot "$workdir" rm -f /etc/sudoers.d/aur
#
# # Cleanup user
# printf '\e[1;32m-->\e[0m\e[1m Performing cleanup\e[0m\n'
# arch-chroot "$workdir" userdel -r aur

# Steam virtual display
# useradd -m -G wheel -s /bin/bash steam
#
# mkdir -p /home/steam/.config
# cat <<EOT >> /home/steam/.config/autostart-virtual-display.sh
# #!/bin/bash
#
# # Create a virtual display using ddcutil
# ddcutil setvcp 60 0x15
# ddcutil setvcp 62 0x1
# ddcutil setvcp 68 0x1
# ddcutil setvcp 8d 0x01
# EOT

# chmod +x /home/steam/.config/autostart-virtual-display.sh

# Create user wolf
arch-chroot "$workdir" useradd -m wolf
arch-chroot "$workdir" passwd -d wolf
arch-chroot "$workdir" usermod -aG input wolf

# Setup SSH for wolf (adds ssh key for remote access)
arch-chroot "$workdir" mkdir -p /home/wolf/.ssh
arch-chroot "$workdir" sh -c 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADD4LxwIuay/NAuqHkr+tlXzQLJbj9BgQGeSjo5ju7h" > /home/wolf/.ssh/authorized_keys'
arch-chroot "$workdir" chown -R wolf:wolf /home/wolf/.ssh
arch-chroot "$workdir" chmod 700 /home/wolf/.ssh
arch-chroot "$workdir" chmod 600 /home/wolf/.ssh/authorized_keys
arch-chroot "$workdir" mkdir -p /home/wolf/wolf-app-state
