#!/usr/bin/env bash
#
# configure.sh — image configuration, run by the Containerfile after the packages
# and the rootfs overlay are in place.
#
# Does four things:
#   1. relocate the Raspberry Pi 5 boot firmware out of /boot/efi (a bootc image
#      may not own that path) and shim bootupctl so `bootc install` puts it back
#   2. create the login user + authorize SSH keys (headless device)
#   3. enable services statically (systemctl enable is unreliable offline)
#   4. write the kernel arguments (serial + HDMI console)
#
# Runs as root inside the image build. $HB points at the build context.
set -euo pipefail

ctx=${HB:-/run/fedora/image}
info() { printf '\e[1;32m-->\e[0m\e[1m %s\e[0m\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }

# --- Raspberry Pi 5 boot firmware ----------------------------------------
# The Pi 5 EEPROM provides no UEFI. It reads config.txt from the FAT32 ESP, loads
# the GPU firmware + DTB, then U-Boot (as `rpi-u-boot.bin`), which finally gives
# GRUB/bootc the EFI environment they expect. Fedora's bcm283x-firmware installs
# those files straight into /boot/efi — but on a bootc/ostree system /boot is
# owned by the installer, not the image, so we stash them in /usr/lib and let the
# bootupctl shim below copy them onto the real ESP during `bootc install`.
fw=/usr/lib/bootc-rpi-firmware
info "Relocating Raspberry Pi firmware to $fw"
mkdir -p "$fw"
shopt -s nullglob
cp -aP /boot/efi/*.dtb /boot/efi/*.bin /boot/efi/*.txt /boot/efi/*.dat \
	/boot/efi/*.elf /boot/efi/overlays "$fw"/ 2>/dev/null || true
shopt -u nullglob
cp -aP /usr/share/uboot/rpi_arm64/u-boot.bin "$fw/rpi-u-boot.bin" \
	|| warn "u-boot.bin not found — the Pi will not boot (uboot-images-armv8 missing?)"

[[ -e $fw/bcm2712-rpi-5-b.dtb ]] \
	|| warn "bcm2712-rpi-5-b.dtb MISSING from $fw — this image will NOT boot on a Pi 5"

# Fedora's config.txt normally already chainloads U-Boot; make sure of it, since
# without this line the firmware looks for a kernel8.img that isn't there.
if [[ -f $fw/config.txt ]] && ! grep -q 'rpi-u-boot.bin' "$fw/config.txt"; then
	info "Adding kernel=rpi-u-boot.bin to config.txt"
	printf '\nkernel=rpi-u-boot.bin\n' >> "$fw/config.txt"
fi

rm -rf /boot/efi
dnf -y remove bcm283x-firmware bcm283x-overlays uboot-images-armv8 >/dev/null \
	|| warn "could not remove the firmware build packages"
# `dnf remove` takes /boot/efi with it; the files we need live in $fw now.
rm -rf /boot/efi

# bootupd has no Raspberry Pi support (coreos/bootupd#766), so wrap it: on
# `bootupctl backend install`, which `bootc install` (and therefore
# image-builder) calls, drop our firmware onto the ESP.
# ponytail: a shell shim, not a bootupd patch. Delete it once bootupd learns to
# install Pi firmware itself.
#
# The real binary is moved into a DIRECTORY and keeps the name `bootupctl`:
# bootupd is a multicall binary that picks its verb set from argv[0]
# (`bootupctl` -> the ctl verbs incl. `backend`, anything else -> the daemon
# verbs, which have no `backend`). Renaming the file makes `bootc install`
# die with "unrecognized subcommand 'backend'".
info "Installing the bootupctl Pi-firmware shim"
if [[ -f /usr/bin/bootupctl && ! -f /usr/libexec/bootupd-orig/bootupctl ]]; then
	mkdir -p /usr/libexec/bootupd-orig
	mv /usr/bin/bootupctl /usr/libexec/bootupd-orig/bootupctl
fi
cat > /usr/bin/bootupctl <<'EOF'
#!/usr/bin/env bash
# Shim: let bootupd install the bootloader, then add the Raspberry Pi firmware
# the EEPROM needs (config.txt, the DTBs, U-Boot) to the same ESP.
set -eu
real=/usr/libexec/bootupd-orig/bootupctl
fw=/usr/lib/bootc-rpi-firmware

# Anything that isn't the real install (notably bootc's `backend install --help`
# probe) just passes through.
for a in "$@"; do [[ $a == --help || $a == -h ]] && exec "$real" "$@"; done
[[ ${1:-} == backend && ${2:-} == install ]] || exec "$real" "$@"

# Run bootupd FIRST. It mounts the real ESP itself, over the deliberately empty
# <chroot>/boot/efi, and unmounts it again when done — so writing there before
# it runs puts the files UNDER a mountpoint, where they vanish. Afterwards the
# ESP is identifiable as the directory holding the EFI/ tree bootupd just wrote.
rc=0
"$real" "$@" || rc=$?
[[ $rc -eq 0 ]] || exit "$rc"

dest=${!#}
esp=
for c in /sysroot/boot/efi "${dest%/}/boot/efi" /boot/efi; do
	[[ -d $c/EFI ]] && { esp=$c; break; }
done
if [[ -z $esp ]]; then
	echo "bootupctl-shim: ERROR: no ESP found (looked for an EFI/ dir under" \
		"/sysroot/boot/efi, ${dest%/}/boot/efi, /boot/efi) — Pi firmware NOT installed" >&2
	exit 1
fi
echo "bootupctl-shim: installing Raspberry Pi firmware into $esp/" >&2
# -rL, not -a: the ESP is FAT32, which has neither hard links nor symlinks, and
# Fedora's firmware set contains hardlinked pairs (fixup_cd.dat/fixup4cd.dat).
# `cp -a` would try to recreate those links and fail with EPERM.
cp -rL "$fw/." "$esp/"
EOF
chmod 0755 /usr/bin/bootupctl

# --- Timezone / locale ---------------------------------------------------
ln -sf ../usr/share/zoneinfo/UTC /etc/localtime
printf 'LANG=C.UTF-8\n' > /etc/locale.conf

# --- Login user ----------------------------------------------------------
# Baked into the image's /etc/passwd+/etc/shadow rather than set by an installer:
# it then works under every install path (raw image flash included).
# ponytail: password is literally "fedora". Change it on first login, or drop an
# authorized_keys next to the Containerfile and disable password auth below.
info 'Creating login user "fedora"'
mkdir -p /var/home
getent passwd fedora >/dev/null 2>&1 || useradd -m -G wheel fedora
echo 'fedora:fedora' | chpasswd

if [[ -s $ctx/authorized_keys ]]; then
	info "Installing SSH authorized_keys for fedora"
	install -d -m 0700 -o fedora -g fedora /var/home/fedora/.ssh
	install -m 0600 -o fedora -g fedora "$ctx/authorized_keys" \
		/var/home/fedora/.ssh/authorized_keys
	# Keys present ⇒ no reason to accept passwords over the network.
	mkdir -p /etc/ssh/sshd_config.d
	printf 'PasswordAuthentication no\nPermitRootLogin no\n' \
		> /etc/ssh/sshd_config.d/10-no-password.conf
else
	warn "no image/authorized_keys — SSH password login stays enabled (user/pass: fedora/fedora)"
fi

# --- Enable services statically ------------------------------------------
# `systemctl enable` does not work reliably in an offline image build (the /etc
# symlinks are not written or do not survive into the deployment), so write the
# .wants symlinks into the immutable /usr tree instead.
enable_unit() {
	local unit=$1 target=${2:-multi-user.target} src="" d
	for d in /etc/systemd/system /usr/lib/systemd/system; do
		[[ -e $d/$unit ]] && { src=$d/$unit; break; }
	done
	[[ -n $src ]] || { warn "unit $unit not found; NOT enabled (package missing?)"; return; }
	mkdir -p "/usr/lib/systemd/system/${target}.wants"
	ln -sfn "$src" "/usr/lib/systemd/system/${target}.wants/$unit"
}

info "Enabling services"
enable_unit NetworkManager.service
enable_unit sshd.service
enable_unit podman.socket sockets.target

# The container-derived base does not statically enable getty@tty1 (containers
# have no VTs), so on real hardware the HDMI console gets no login prompt. Enable
# the instance the way systemd itself does: a wants-symlink named for the
# instance, pointing at the template.
if [[ -e /usr/lib/systemd/system/getty@.service ]]; then
	mkdir -p /usr/lib/systemd/system/getty.target.wants
	ln -sfn ../getty@.service /usr/lib/systemd/system/getty.target.wants/getty@tty1.service
else
	warn "getty@.service template missing; the HDMI console will have no login prompt"
fi

# --- Kernel arguments ----------------------------------------------------
# Baked via bootc kargs.d, so they are applied by `bootc install` (image-builder)
# AND preserved across day-2 `bootc upgrade`.
#   console=tty1              HDMI console
#   console=ttyAMA0,115200    Pi 5 UART header — the only way to see an early
#                             boot failure on a headless box
info "Writing kernel arguments"
mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/10-console.toml <<'EOF'
# Log to both the HDMI console and the Pi 5 serial header (last one wins for
# /dev/console, so keep the serial console last).
kargs = ["console=tty1", "console=ttyAMA0,115200"]
EOF

# --- Sanity checks -------------------------------------------------------
# The bulk install uses --skip-broken/--skip-unavailable, which silently drops a
# package (and its dependants). Surface that in the build log.
for chk in \
	"NetworkManager:/usr/lib/systemd/system/NetworkManager.service" \
	"sshd:/usr/lib/systemd/system/sshd.service" \
	"pi-firmware:/usr/lib/bootc-rpi-firmware/rpi-u-boot.bin" \
	"growpart:/usr/bin/growpart" \
	"growpart drop-in:/usr/lib/systemd/system/bootc-generic-growpart.service.d/10-grow-on-bare-metal.conf" \
	"brcmfmac firmware:/usr/lib/firmware/brcm"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || warn "MISSING: $name ($path) — check the install log above"
done

# The drop-in above is useless if the vendor unit ever stops shipping or stops
# being enabled, and the failure is silent (a card stuck at the image size).
gp=/usr/lib/systemd/system/bootc-generic-growpart.service
if [[ ! -e $gp ]]; then
	warn "$gp is gone — the rootfs will NOT grow to fill the card"
elif [[ ! -e /usr/lib/systemd/system/local-fs.target.wants/bootc-generic-growpart.service ]]; then
	warn "bootc-generic-growpart.service is not enabled — the rootfs will NOT grow"
fi

info "configure complete"
