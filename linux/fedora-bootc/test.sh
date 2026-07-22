#!/usr/bin/env bash
#
# test.sh — pre-flight inspection of a built image, so we catch problems BEFORE
# the slow install+boot cycle. Runs read-only inside the image with podman.
#
# Covers the two open risks:
#   1. LUKS unlock  — the root disk driver (`nvme`) must be in the initramfs and
#                     force-loaded, or the disk never appears and LUKS never prompts
#                     ("Timed out waiting for device"); PLUS the systemd-cryptsetup
#                     module + a RESOLVING binary (a dangling symlink fails silently).
#                     NOTE: the install-time `rd.luks.uuid=` karg is the ONE thing
#                     that can't be checked here — verify it post-boot with
#                     `cat /proc/cmdline | tr ' ' '\n' | grep luks`.
#   2. Blank screen — GPU driver kept OUT of the initramfs, GPU firmware present
#                     ON the real root, and the desktop/DM stack installed+enabled.
#
# Usage: ./test.sh [image]   (default: localhost/fedora-gnome-sway:latest — the
# flavor image, which inherits the base initramfs and adds the desktop.)
set -euo pipefail

img=${1:-localhost/fedora-gnome-sway:latest}
PODMAN=${PODMAN:-podman}

sudo "$PODMAN" run --rm "$img" bash -c '
kver=$(ls /usr/lib/modules)
img=/usr/lib/modules/$kver/initramfs.img
sep() { printf "\n\e[1;36m== %s ==\e[0m\n" "$1"; }

sep "kernel"
echo "$kver"

sep "LUKS: systemd-cryptsetup binary resolves? (dangling = unlock fails)"
bin=/usr/lib/systemd/systemd-cryptsetup
ls -l "$bin"; readlink -f "$bin"; [ -x "$(readlink -f "$bin")" ] && echo "OK: resolves + executable" || echo "!! BROKEN symlink / not executable"

sep "LUKS: initramfs content"
lc=$(lsinitrd "$img" 2>/dev/null | wc -l); echo "lsinitrd lines: $lc"
lsinitrd -m "$img" 2>/dev/null | grep -qw systemd-cryptsetup && echo "OK: systemd-cryptsetup module in initramfs" || echo "!! systemd-cryptsetup module MISSING"
lsinitrd -m "$img" 2>/dev/null | grep -qw crypt && echo "OK: crypt module" || echo "!! crypt module MISSING"
lsinitrd "$img" 2>/dev/null | grep -q "systemd-cryptsetup-generator" && echo "OK: cryptsetup generator present" || echo "!! generator MISSING"

sep "LUKS: root disk driver (nvme) — must be in the initramfs (force-loaded at start)"
# On this rawhide the generic initramfs does NOT autoload nvme, so the root disk
# never appears and systemd-cryptsetup times out with NO passphrase prompt. We force
# it in via force_drivers; verify the module is baked in.
lsinitrd "$img" 2>/dev/null | grep -Eq "/nvme\.ko" && echo "OK: nvme driver in initramfs" || echo "!! nvme driver MISSING (root disk will NOT appear, LUKS never prompts)"

sep "LUKS: dracut crypt module unit-name escaping (must NOT double backslashes)"
# Rawhide udev no longer unescapes RUN= strings, so dracut'"'"'s default backslash
# doubling makes `systemctl start systemd-cryptsetup@luks\\x2d….service` match no unit
# and NORMAL boot loops. configure.sh patches parse-crypt.sh to single-escape.
# ponytail: the module dir moved 70crypt -> 90crypt upstream once already, so find
# it by name via the initramfs file listing instead of hardcoding the number.
parse_crypt_path=$(lsinitrd -l "$img" 2>/dev/null | grep -o 'usr/lib/dracut/modules\.d/[0-9]*crypt/parse-crypt\.sh' | head -1)
if [[ -z $parse_crypt_path ]]; then
	echo "!! parse-crypt.sh not found in initramfs — cannot verify escaping"
elif lsinitrd -f "$parse_crypt_path" "$img" 2>/dev/null | grep -q "str_replace \"\$luksname\""; then
	echo "!! $parse_crypt_path STILL doubles backslashes (LUKS will loop on normal boot)"
else
	echo "OK: $parse_crypt_path single-escapes systemd-cryptsetup unit name"
fi

sep "root: ostree + composefs + fs drivers in initramfs"
lsinitrd -m "$img" 2>/dev/null | grep -qw ostree && echo "OK: ostree module" || echo "!! ostree MISSING (unbootable)"
for m in erofs overlay xfs; do lsinitrd "$img" 2>/dev/null | grep -q "/$m\.ko" && echo "OK: $m.ko" || echo "!! $m.ko MISSING"; done

sep "GPU: no KMS driver LEAKED into initramfs (must be empty)"
if lsinitrd "$img" 2>/dev/null | grep -E "/(i915|xe|amdgpu)\.ko"; then echo "!! GPU driver leaked (reintroduces black screen)"; else echo "OK: no GPU KMS driver in initramfs"; fi

sep "GPU: firmware present ON THE REAL ROOT (where userspace i915 needs it)"
{ ls -d /usr/lib/firmware/i915 >/dev/null 2>&1 && ls /usr/lib/firmware/i915 | grep -iqE "guc|huc" && echo "OK: i915 GuC/HuC firmware present"; } || echo "!! /usr/lib/firmware/i915 GuC/HuC firmware MISSING (install linux-firmware / intel-gpu-firmware)"
rpm -q linux-firmware 2>/dev/null || echo "!! linux-firmware not installed"

sep "desktop stack installed"
for p in gdm gnome-shell mutter sway hyprland xorg-x11-server-Xwayland gnome-session gnome-settings-daemon mesa-dri-drivers; do
  rpm -q "$p" >/dev/null 2>&1 && echo "OK: $p" || echo "!! MISSING: $p"
done

sep "default boot target"
readlink -f /etc/systemd/system/default.target 2>/dev/null || readlink -f /usr/lib/systemd/system/default.target 2>/dev/null || systemctl get-default 2>/dev/null

sep "display-manager enablement"
echo "graphical.target.wants (this is what actually starts the DM):"
ls -l /usr/lib/systemd/system/graphical.target.wants/*dm*.service /etc/systemd/system/graphical.target.wants/*dm*.service 2>/dev/null || echo "!! no DM in graphical.target.wants — DM will NOT start under graphical.target"
echo "display-manager.service alias:"
readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || echo "(no display-manager.service)"

sep "login user: fedora exists, is in wheel, has a usable (non-locked) password"
getent passwd fedora >/dev/null 2>&1 && echo "OK: fedora user present" || echo "!! fedora user MISSING (console login will fail)"
id -nG fedora 2>/dev/null | grep -qw wheel && echo "OK: fedora in wheel (sudo)" || echo "!! fedora NOT in wheel"
# /etc/shadow field 2 must be a real hash: empty = no password, ! or * = locked.
hash=$(getent shadow fedora 2>/dev/null | cut -d: -f2)
case "$hash" in
  ""|"!"*|"*") echo "!! fedora password locked/empty ($hash) — login will fail \"incorrect\"";;
  *)           echo "OK: fedora has a hashed password";;
esac

sep "zsh completion: /etc/zshrc must source /etc/zshrc.d (else compinit/compdef undefined)"
# Fedora stock /etc/zshrc does NOT read /etc/zshrc.d; configure.sh appends the loop.
grep -q "/etc/zshrc.d/\*\.zsh" /etc/zshrc 2>/dev/null \
	&& echo "OK: /etc/zshrc sources /etc/zshrc.d" \
	|| echo "!! /etc/zshrc does NOT source /etc/zshrc.d — compinit/compdef will be undefined"
[ -f /etc/zshrc.d/00-fedora-compinit.zsh ] && echo "OK: compinit drop-in present" || echo "!! compinit drop-in MISSING"

sep "local VT login (getty on tty1)"
ls -l /usr/lib/systemd/system/getty.target.wants/getty@tty1.service 2>/dev/null \
	&& echo "OK: getty@tty1 enabled — physical console gets a login prompt" \
	|| echo "!! getty@tty1 NOT enabled — only serial console will get a login prompt"

sep "ssh should be DISABLED (desktop device)"
rpm -q openssh-server >/dev/null 2>&1 && echo "!! openssh-server still installed" || echo "OK: openssh-server not installed"

sep "kernel args baked by image (bootc kargs.d; the anaconda-iso installer applies these)"
cat /usr/lib/bootc/kargs.d/*.toml 2>/dev/null || echo "(none)"
'
