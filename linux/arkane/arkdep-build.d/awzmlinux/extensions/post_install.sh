#!/bin/sh

# reference custom sway startup script in systemd unit
arch-chroot "$workdir" sed -i -e 's|Exec=.*|Exec=/usr/local/bin/sway-egpu|g' /usr/share/wayland-sessions/sway.desktop

# remove fallback hyprland configuration
arch-chroot "$workdir" rm -f /usr/share/hypr/hyprland.conf

# workaround for https://www.reddit.com/r/archlinux/comments/1ja6y69/it_looks_like_linuxfirmware_20250311b69d4b742_has/
#TMP_DIR=$(mktemp -d)
#curl -L https://archive.archlinux.org/packages/l/linux-firmware/linux-firmware-20250210.5bc5868b-1-any.pkg.tar.zst -o $TMP_DIR/linux-firmware-20250210.5bc5868b-1-any.pkg.tar.zst
#pacman -U --noconfirm $TMP_DIR/linux-firmware-20250210.5bc5868b-1-any.pkg.tar.zst
#rm -rf $TMP_DIR

# set hostname
arch-chroot "$workdir" hostnamectl set-hostname 'L0223-1024'

# Install AUR packages
# Set list of AUR packages to install
aur_packages=('yay-bin' 'paru-bin' 'intel-ipu7-camera-bin')

# Install build dependencies
printf '\e[1;32m-->\e[0m\e[1m Installing build dependencies\e[0m\n'
arch-chroot "$workdir" pacman -Sy --noconfirm --needed base-devel git

# Create temporary unprivileged user, required for fakeroot
printf '\e[1;32m-->\e[0m\e[1m Creating temporary user\e[0m\n'
arch-chroot "$workdir" useradd aur -m -p '!'

# Allow 'aur' to use sudo without password
printf '\e[1;32m-->\e[0m\e[1m Allowing aur user passwordless sudo\e[0m\n'
arch-chroot "$workdir" bash -c "echo 'aur ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/aur"

# Build and install packages from pkgbuild
printf '\e[1;32m-->\e[0m\e[1m Building and installing local packages\e[0m\n'
pkgbuild_dir="arkdep-build.d/awzmlinux/pkgbuild"
for pkg in "$pkgbuild_dir"/*; do
  if [ -d "$pkg" ]; then
    pkg_name=$(basename "$pkg")
    printf "\e[1;32m-->\e[0m\e[1m Building $pkg_name\e[0m\n"
    cp -r "$pkg" "$workdir/home/aur/"
    arch-chroot "$workdir" chown -R aur:aur "/home/aur/$pkg_name"
    arch-chroot -u aur:aur "$workdir" bash -c "cd /home/aur/$pkg_name && makepkg -si --noconfirm"
  fi
done

# Install yay manually first (because we need it to install others)
printf '\e[1;32m-->\e[0m\e[1m Bootstrapping yay-bin\e[0m\n'
arch-chroot -u aur:aur "$workdir" bash -c "
  cd /home/aur &&
  git clone https://aur.archlinux.org/yay-bin.git &&
  cd yay-bin &&
  makepkg -si --noconfirm
"

# Install AUR packages using yay
for package in "${aur_packages[@]}"; do
    printf "\e[1;32m-->\e[0m\e[1m Installing $package using yay\e[0m\n"
    arch-chroot -u aur:aur "$workdir" bash -c "yay -S --noconfirm $package"
done

# Cleanup sudoers file
printf '\e[1;32m-->\e[0m\e[1m Removing temporary sudoers rule\e[0m\n'
arch-chroot "$workdir" rm -f /etc/sudoers.d/aur

# Cleanup user
printf '\e[1;32m-->\e[0m\e[1m Performing cleanup\e[0m\n'
arch-chroot "$workdir" userdel -r aur
