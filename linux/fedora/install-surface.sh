#/bin/sh

# add repository
sudo dnf -y config-manager \
  --add-repo=https://pkg.surfacelinux.com/fedora/linux-surface.repo

# install surface kernel
sudo dnf -y install --allowerasing \
  kernel-surface \
  kernel-surface-devel \
  iptsd \
  libwacom-surface

# enable touchscreen support
sudo systemctl enable iptsd

# enable secure boot
sudo dnf -y install surface-secureboot

# write systemd path, so surface kernel is always
# being used (instead of the fedora default kernel)
sudo tee "/etc/systemd/system/default-kernel.path" > /dev/null <<'EOF'
[Unit]
Description=Fedora default kernel updater

[Path]
PathChanged=/boot

[Install]
WantedBy=default.target
EOF

sudo tee "/etc/systemd/system/default-kernel.service" > /dev/null <<'EOF'
[Unit]
Description=Fedora default kernel updater

[Service]
Type=oneshot
ExecStart=/bin/sh -c "grubby --set-default /boot/vmlinuz*surface*"
EOF

sudo systemctl enable default-kernel.path

# set surface kernel as default in grub
sudo grubby --set-default /boot/vmlinuz*surface*
