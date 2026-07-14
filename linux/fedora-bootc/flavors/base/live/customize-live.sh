#!/usr/bin/env bash
#
# customize-live.sh — tacklebox `live_customize` hook.
#
# Tacklebox runs this INSIDE a container of the flavor image (as root, with
# network) right before squashing it into the live ISO. We use it to turn the
# live environment into a headless TTY installer: autologin root on tty1 and run
# flavors/base/live/install.sh (the LUKS + `bootc install to-filesystem` recipe).
# No desktop / GDM / livesys / installer-Flatpak — just a console.
#
# CREDIT: the live_customize + autolaunch pattern is adapted from tunaOS
# (tuna-os/tunaOS live-iso/common/src/*.sh) and tuna-os/tacklebox, both Apache-2.0.
# tunaOS autolaunches a GUI installer Flatpak via SDDM/greetd autologin + XDG
# autostart; we replace that with a getty autologin + shell-profile launch so the
# installer is a plain TTY script.
set -euo pipefail

# The script's own directory is the cwd (mounted by tacklebox), so install.sh
# sits next to us. Ship it onto the live rootfs.
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install -Dm0755 "$here/install.sh" /usr/libexec/fedora-install

# Tools the installer needs that the base might not carry (base has cryptsetup /
# xfsprogs / e2fsprogs / util-linux / podman already; dosfstools + gdisk are the
# usual gaps). --skip-* so a missing one warns instead of failing the squash.
dnf -y install --setopt=install_weak_deps=False --skip-unavailable --skip-broken \
	dosfstools gdisk util-linux cryptsetup podman || true

# Offline image store (tacklebox `offline_payloads`). Tacklebox packs the flavor
# image into LiveOS/store.squashfs.img on the ISO, but only tacklebox-PREPARED
# images auto-mount it — a generic bootc image like ours ships neither the mount
# nor the containers/storage wiring. Bake both so the installer can resolve
# `containers-storage:<image>` offline (adapted from tuna-os/tacklebox
# internal/install/offline_store.go, Apache-2.0). install.sh loop-mounts the
# squashfs at /var/lib/superiso-store; this drop-in makes it an additional store.
mkdir -p /var/lib/superiso-store /etc/containers/storage.conf.d
cat > /etc/containers/storage.conf.d/99-tbox-store.conf <<-'EOF'
	# Tacklebox offline image store (mounted from the ISO by install.sh). Lets
	# podman/bootc resolve containers-storage:<ref> without a network.
	[storage.options]
	additionalimagestores = ["/var/lib/superiso-store"]
EOF

# Boot the LIVE env to a console, not a desktop — the installer is TTY-only.
systemctl set-default multi-user.target

# Silence bootloader-update.service in the live env: it runs `bootctl update`
# against an installed-system ESP that doesn't exist here, so it just fails
# noisily ("Failed to start bootloader-update.service"). Masking only affects
# this live squashfs, not the image we install (that comes from the offline
# store copy, untouched by this script).
systemctl mask bootloader-update.service 2>/dev/null || true

# Autologin root on tty1 (throwaway live env; the installer needs root anyway).
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<-'EOF'
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
EOF

# Launch the installer once, on tty1 only, then drop to a shell (so a failed or
# aborted install leaves a usable console instead of a login loop).
cat > /root/.bash_profile <<-'EOF'
	if [[ $(tty) == /dev/tty1 && -z ${FEDORA_INSTALL_DONE:-} ]]; then
		export FEDORA_INSTALL_DONE=1
		/usr/libexec/fedora-install || true
		echo; echo "Installer exited. You are on a live shell (tty1)."
	fi
EOF

echo "customize-live: TTY installer wired (autologin root -> /usr/libexec/fedora-install)"
