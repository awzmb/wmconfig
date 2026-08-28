#!/usr/bin/env bash
#
# test.sh — pre-flight inspection of the built image, so problems are caught
# BEFORE the slow flash + boot cycle. Runs read-only inside the image.
#
# Covers what can actually go wrong here:
#   1. the Pi 5 boot chain — firmware + DTB + U-Boot staged in /usr/lib and the
#      bootupctl shim that copies them onto the ESP during install
#   2. headless access — sshd and a login user that can actually log in
#   3. the image is aarch64
#
# Usage: ./test.sh [image]   (default: localhost/fedora-rpi5:latest)
#
# Run it with the same privilege you built with — a rootless build is invisible
# to root's podman storage and vice versa (so `sudo ./fedora-build` pairs with
# `sudo ./test.sh`). On an x86_64 host it needs the aarch64 binfmt handler.
set -euo pipefail

img=${1:-localhost/fedora-rpi5:latest}
PODMAN=${PODMAN:-podman}

arch=$("$PODMAN" image inspect --format '{{.Architecture}}' "$img" 2>/dev/null || echo "?")
printf '\n\e[1;36m== architecture ==\e[0m\n'
[[ $arch == arm64 ]] && echo "OK: $arch" || echo "!! image is '$arch', not arm64 — it will NOT boot on a Pi 5"

# ponytail: the probe is fed on stdin as a quoted heredoc rather than `bash -c
# '\''...'\''` — inside a single-quoted argument every apostrophe in a message or grep
# pattern silently truncates the script. Heredoc has no such trap.
"$PODMAN" run --rm -i --platform linux/arm64 "$img" bash -s <<'PROBE'
sep() { printf "\n\e[1;36m== %s ==\e[0m\n" "$1"; }
ok()  { printf "OK: %s\n" "$1"; }
bad() { printf "!! %s\n" "$1"; }

sep "kernel"
ls /usr/lib/modules

sep "Pi 5 boot chain staged in /usr/lib/bootc-rpi-firmware"
fw=/usr/lib/bootc-rpi-firmware
for f in rpi-u-boot.bin bcm2712-rpi-5-b.dtb config.txt; do
  [ -e "$fw/$f" ] && ok "$f" || bad "$f MISSING — the Pi will not boot"
done
[ -d "$fw/overlays" ] && ok "overlays/" || bad "overlays/ MISSING"

sep "bootupctl shim (copies the firmware onto the ESP during bootc install)"
grep -q bootc-rpi-firmware /usr/bin/bootupctl 2>/dev/null && ok "shim installed" || bad "bootupctl is NOT shimmed — the ESP will have no Pi firmware"
[ -x /usr/libexec/bootupd-orig/bootupctl ] && ok "real bootupctl preserved under its own name" || bad "/usr/libexec/bootupd-orig/bootupctl MISSING — bootc install will fail"
/usr/libexec/bootupd-orig/bootupctl backend install --help >/dev/null 2>&1 \
	&& ok "real bootupctl still answers 'backend install' (multicall argv[0] intact)" \
	|| bad "real bootupctl rejects 'backend install' — it must keep the basename 'bootupctl'"

sep "no package-owned /boot/efi left in the image (bootc lint / install conflict)"
[ -e /boot/efi ] && bad "/boot/efi still exists in the image" || ok "/boot/efi absent"

sep "Wi-Fi firmware (Pi 5 = CYW43455 / brcmfmac)"
ls /usr/lib/firmware/brcm/brcmfmac43455* >/dev/null 2>&1 && ok "brcmfmac43455 firmware present" || bad "brcmfmac43455 firmware MISSING — no Wi-Fi"

sep "headless access"
[ -e /usr/lib/systemd/system/multi-user.target.wants/sshd.service ] && ok "sshd enabled" || bad "sshd NOT enabled — no way in on a headless box"
[ -e /usr/lib/systemd/system/multi-user.target.wants/NetworkManager.service ] && ok "NetworkManager enabled" || bad "NetworkManager NOT enabled — no network"
[ -e /usr/lib/systemd/system/getty.target.wants/getty@tty1.service ] && ok "getty@tty1 enabled" || bad "getty@tty1 NOT enabled — no HDMI login prompt"

sep "login user"
getent passwd fedora >/dev/null && ok "fedora user present" || bad "fedora user MISSING"
id -nG fedora 2>/dev/null | grep -qw wheel && ok "fedora in wheel (sudo)" || bad "fedora NOT in wheel"
hash=$(getent shadow fedora 2>/dev/null | cut -d: -f2)
case "$hash" in
  ""|"!"*|"*") bad "fedora password locked/empty — password login will fail";;
  *)           ok "fedora has a hashed password";;
esac
[ -s /var/home/fedora/.ssh/authorized_keys ] && ok "authorized_keys installed" || echo "(no authorized_keys baked in — password login only)"

sep "kernel args baked by the image (bootc kargs.d)"
cat /usr/lib/bootc/kargs.d/*.toml 2>/dev/null || bad "no kargs.d — no serial console for debugging"

sep "rootfs growth (fill the card on first boot)"
command -v growpart >/dev/null 2>&1 && ok "growpart present" || bad "growpart MISSING — rootfs cannot grow (cloud-utils-growpart)"
[ -e /usr/lib/systemd/system/local-fs.target.wants/bootc-generic-growpart.service ] \
	&& ok "bootc-generic-growpart.service enabled" \
	|| bad "bootc-generic-growpart.service not enabled — rootfs will stay at the image size"
# The vendor unit is guarded by ConditionVirtualization=vm, which is FALSE on a
# Pi. Our drop-in resets that condition; without it the card silently stays small.
grep -rq '^ConditionVirtualization=$' \
	/usr/lib/systemd/system/bootc-generic-growpart.service.d/ 2>/dev/null \
	&& ok "ConditionVirtualization guard lifted (grows on bare metal)" \
	|| bad "no drop-in clearing ConditionVirtualization — the rootfs will NOT grow on a Pi"

sep "cephfs flavor"
# Only meaningful on the cephfs image; the base image legitimately has none of this.
if command -v cephadm >/dev/null 2>&1; then
  for b in ceph mount.ceph ceph-fuse chronyd lvm nvme; do
    command -v "$b" >/dev/null 2>&1 && ok "$b" || bad "$b MISSING"
  done
  [ -e /usr/lib/systemd/system/multi-user.target.wants/chronyd.service ] && ok "chronyd enabled (Ceph needs time sync)" || bad "chronyd NOT enabled — monitors will reject this node on clock skew"
  [ -e /usr/lib/systemd/system/multi-user.target.wants/lvm2-monitor.service ] && ok "lvm2-monitor enabled" || bad "lvm2-monitor NOT enabled"
  grep -q aio-max-nr /etc/sysctl.d/90-ceph.conf 2>/dev/null && ok "ceph sysctl tuning present" || bad "/etc/sysctl.d/90-ceph.conf MISSING"
  grep -q '^dtparam=pciex1' /usr/lib/bootc-rpi-firmware/config.txt 2>/dev/null && ok "PCIe enabled in config.txt (NVMe will enumerate)" || bad "dtparam=pciex1 MISSING from config.txt — the NVMe may not appear at all"
  grep -q max_host_mem_size_mb /usr/lib/bootc/kargs.d/*.toml 2>/dev/null && ok "NVMe HMB cap raised (DRAM-less drives stall without it)" || bad "nvme.max_host_mem_size_mb MISSING — a DRAM-less NVMe will lock up under sustained IO"
  kver=$(ls /usr/lib/modules | head -1)
  find "/usr/lib/modules/$kver" -name "ceph.ko*" -print -quit | grep -q . && ok "kernel ceph.ko present" || bad "ceph.ko MISSING — no kernel CephFS mounts"
  [ -d /etc/ceph ] && ok "/etc/ceph present (cephadm writes ceph.conf + keyring here)" || bad "/etc/ceph MISSING"
else
  echo "(base image — no ceph tooling, as expected)"
fi

sep "size"
du -sh /usr 2>/dev/null | cut -f1
PROBE
