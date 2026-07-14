#!/usr/bin/env bash
#
# install.sh — the bootc/LUKS installer that runs INSIDE the live ISO.
#
# Set up LUKS ourselves, then `bootc install to-filesystem` into the already-open
# mapper, so bootc never touches LUKS and we own the unlock story. It replaces the
# old Anaconda-kickstart path (bib anaconda-iso) — see flavors/base/bib/.
#
# CREDIT: the install recipe (partition -> LUKS -> to-filesystem -> BLS karg patch)
# and the `rd.luks.name=<uuid>=root` fix are adapted from the tunaOS ecosystem,
# all Apache-2.0:
#   - tuna-os/tacklebox            https://github.com/tuna-os/tacklebox
#   - projectbluefin/fisherman     https://github.com/projectbluefin/fisherman
#   - projectbluefin/dakota-iso    https://github.com/projectbluefin/dakota-iso
#     (LUKS design notes: bootc-migrate-composefs/docs/luks-testing.md)
#
# Layout (grub2 / ostree base = quay.io/fedora/fedora-bootc:rawhide):
#   p1  EFI System   FAT32   ESP / bootloader
#   p2  /boot        ext4    UNENCRYPTED — GRUB can't read an xfs/LUKS root, and
#                            bootupctl reads the boot-fs UUID off the raw device
#   p3  root         LUKS2 -> xfs   encrypted root
#
# The one detail that MUST be right (dakota #270): the unlock karg is
#   rd.luks.name=<LUKS-header-UUID>=root
# which maps the container to /dev/mapper/root so systemd-gpt-auto-generator finds
# root. `rd.luks.uuid=` (-> /dev/mapper/luks-<uuid>) or a bare name hangs ~90s into
# an emergency shell. No /etc/crypttab is needed; the initrd `crypt` module unlocks
# from this karg. The installed image already ships crypt/systemd-cryptsetup and
# force-loads nvme (flavors/base/overlay/etc/dracut.conf.d/fedora.conf).
#
# Usage (run as root in the live env):
#   install.sh [--disk /dev/sdX] [--image <ref>] [--self-test]
#   FEDORA_INSTALL_DISK / FEDORA_INSTALL_IMAGE / FEDORA_INSTALL_PASSPHRASE env vars
#   also work (the latter for unattended installs — otherwise we prompt).
set -euo pipefail

die() { printf '\e[1;31m==> error:\e[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\e[1;32m==>\e[0m\e[1m %s\e[0m\n' "$*"; }
warn() { printf '\e[1;33m==> warning:\e[0m %s\n' "$*" >&2; }

# --- inject_luks_arg: append the LUKS unlock karg to every BLS entry ----------
# Kept as a function so the exact-form logic (the boot-critical bit) is unit-
# testable via --self-test below. Appends once; idempotent.
inject_luks_arg() {
	local entries_dir=$1 luks_uuid=$2 arg
	arg="rd.luks.name=${luks_uuid}=root"
	local f found=0
	for f in "$entries_dir"/*.conf; do
		[[ -f $f ]] || continue
		found=1
		grep -q -- "$arg" "$f" && continue
		# append to the (single) `options` line; leave everything else intact
		sed -i "s|^\(options .*\)|\1 ${arg}|" "$f"
	done
	[[ $found -eq 1 ]] || return 1
}

# --- choose_disk: decide the install target from the disk list ----------------
# Pure (no lsblk) so the erase-target policy is unit-testable: reads whole-disk
# paths on stdin, drops the live-media disk, and echoes "auto <disk>" (exactly
# one candidate), "prompt" (several), or "none".
choose_disk() {
	local live=$1 d; local -a cand=()
	while read -r d; do [[ -z $d || $d == "$live" ]] || cand+=("$d"); done
	case ${#cand[@]} in
		0) echo none ;;
		1) echo "auto ${cand[0]}" ;;
		*) echo prompt ;;
	esac
}

# --- self-test: prove the BLS rewrite produces exactly the right karg form -----
if [[ ${1:-} == --self-test ]]; then
	tmp=$(mktemp -d)
	printf 'title Fedora\noptions root=UUID=fs-1234 rw rhgb quiet\n' > "$tmp/a.conf"
	inject_luks_arg "$tmp" "luks-abcd"
	got=$(grep '^options ' "$tmp/a.conf")
	inject_luks_arg "$tmp" "luks-abcd"                       # second run must be a no-op
	got2=$(grep '^options ' "$tmp/a.conf")
	rm -rf "$tmp"
	[[ $got == "options root=UUID=fs-1234 rw rhgb quiet rd.luks.name=luks-abcd=root" ]] \
		|| die "self-test: wrong karg form: $got"
	[[ $got == "$got2" ]] || die "self-test: not idempotent: $got2"
	# disk-selection policy
	[[ $(printf '/dev/vda\n'                     | choose_disk "")         == "auto /dev/vda" ]] || die "self-test: single disk not auto-selected"
	[[ $(printf '/dev/sda\n/dev/nvme0n1\n'       | choose_disk /dev/sda)   == "auto /dev/nvme0n1" ]] || die "self-test: live disk not excluded"
	[[ $(printf '/dev/vda\n/dev/vdb\n'           | choose_disk "")         == "prompt" ]] || die "self-test: multiple disks should prompt"
	[[ $(printf '/dev/sda\n'                     | choose_disk /dev/sda)   == "none" ]] || die "self-test: only-live-disk should be none"
	info "self-test OK"
	exit 0
fi

# --- args --------------------------------------------------------------------
disk=${FEDORA_INSTALL_DISK:-}
image=${FEDORA_INSTALL_IMAGE:-}
passphrase=${FEDORA_INSTALL_PASSPHRASE:-}
mnt=/mnt/fedora-target
mapper=fedora-root

while [[ $# -gt 0 ]]; do
	case "$1" in
		--disk)  disk=$2; shift 2;;
		--image) image=$2; shift 2;;
		-h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0;;
		*) die "unknown argument: $1";;
	esac
done

[[ $(id -u) -eq 0 ]] || die "must run as root"

# Quiet the console: the live env boots permissive (enforcing=0), so the kernel
# spams SELinux `avc: denied` + audit lines over our prompts. Drop the console
# loglevel to warnings-only; real errors still land in the journal/dmesg.
# ponytail: cosmetic; remove if you need live avc traces on-console.
dmesg -n 1 2>/dev/null || true

for c in cryptsetup sfdisk mkfs.xfs mkfs.ext4 mkfs.vfat bootc podman lsblk udevadm; do
	command -v "$c" >/dev/null 2>&1 || die "missing required tool: $c"
done

# Offline image store: tacklebox packs the flavor image into the ISO at
# LiveOS/store.squashfs.img (recipe `offline_payloads`). Loop-mount it at
# /var/lib/superiso-store, which customize-live.sh registered as a containers/
# storage additionalimagestore, so `podman images` / bootc can see the image
# offline. (adapted from tuna-os/tacklebox offline_store.go, Apache-2.0)
store=/var/lib/superiso-store
store_sq=/run/initramfs/live/LiveOS/store.squashfs.img
if [[ -f $store_sq ]] && ! mountpoint -q "$store" && ! podman image exists "${image:-}" 2>/dev/null; then
	info "mounting offline image store"
	mkdir -p "$store"
	mount -o loop,ro "$store_sq" "$store" 2>/dev/null \
		|| warn "could not mount offline store (image may already be exposed): $store_sq"
fi

# Source image: default to the single localhost/fedora-* image in the live env's
# storage (from the offline store above). If several exist, the user must pass
# --image. ponytail: naive "first match" pick; --image overrides when ambiguous.
if [[ -z $image ]]; then
	image=$(podman images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
		| grep -m1 '^localhost/fedora-' || true)
	[[ -n $image ]] || die "no localhost/fedora-* image found; pass --image <ref>"
fi

# Which disk backs the live media (ISO/USB)? Exclude it from auto-selection and
# refuse it if passed explicitly. A VM's ISO is a CDROM (type rom, already
# filtered out below); a USB boot is a real disk, so resolve it from what backs
# /run/initramfs/live and drop it from the candidate list.
live_disk=""
live_media=$(findmnt -no SOURCE /run/initramfs/live 2>/dev/null | head -n1 || true)
if [[ -n $live_media ]]; then
	pk=$(lsblk -no PKNAME "$live_media" 2>/dev/null | head -n1)
	[[ -n $pk ]] && live_disk=/dev/$pk
fi

# Target disk: UNATTENDED — auto-select when exactly one installable disk exists;
# only prompt when several are found (or none, which is fatal). --disk / env skip
# all of this. Reads go to /dev/tty so prompts work from a login profile.
interactive=1
if [[ -z $disk ]]; then
	mapfile -t disks < <(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}')
	sel=$(printf '%s\n' "${disks[@]}" | choose_disk "$live_disk")
	case $sel in
		none)  die "no installable disk found. Attach a target disk (ensure its storage driver is loaded) and re-run: /usr/libexec/fedora-install" ;;
		auto\ *) disk=${sel#auto }; interactive=0
		         info "auto-selected the only disk: $disk" ;;
		prompt) info "multiple disks found — choose the install target:"
		        lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$NF=="disk"'
		        while :; do
			        read -r -p "Target disk to ERASE (e.g. ${disks[0]}): " disk </dev/tty || true
			        [[ -b $disk && $disk != "$live_disk" ]] && break
			        warn "pick a valid non-live disk"
		        done ;;
	esac
else
	interactive=0
fi
[[ -b $disk ]] || die "$disk is not a block device"
[[ -n $live_disk && $disk == "$live_disk" ]] && die "$disk hosts the live media; refusing"

# Passphrase (LUKS). Interactive → prompt+confirm. Unattended → default to the
# project's login password ('fedora'); override with FEDORA_INSTALL_PASSPHRASE.
# ponytail: LUKS passphrase == login password by design (see configure.sh).
if [[ -z $passphrase ]]; then
	if [[ $interactive -eq 1 ]]; then
		read -r -s -p "LUKS passphrase for $disk: " passphrase </dev/tty; echo
		read -r -s -p "Confirm passphrase: " confirm </dev/tty; echo
		[[ $passphrase == "$confirm" ]] || die "passphrases do not match"
	else
		passphrase=fedora
		warn "unattended: using default LUKS passphrase 'fedora' (set FEDORA_INSTALL_PASSPHRASE to override)"
	fi
fi
[[ -n $passphrase ]] || die "empty passphrase"

echo
warn "About to ERASE ALL DATA on $disk and install $image (LUKS-encrypted)."
lsblk "$disk"
if [[ $interactive -eq 1 ]]; then
	read -r -p "Type 'ERASE' to continue: " ans </dev/tty
	[[ $ans == ERASE ]] || die "aborted"
else
	warn "unattended install starts in 5s — Ctrl-C to abort"; sleep 5
fi

# --- 1. partition (GPT: ESP + ext4 /boot + LUKS root) ------------------------
info "partitioning $disk"
sfdisk --wipe=always "$disk" <<-EOF
	label: gpt
	size=2GiB, type=uefi, name="EFI-SYSTEM"
	size=2GiB, type=linux, name="boot"
	type=linux, name="root"
EOF
udevadm settle

# nvme uses pNN suffixes (nvme0n1p1); sd*/vd* don't (sda1). Resolve via lsblk.
mapfile -t parts < <(lsblk -lno NAME "$disk" | tail -n +2 | sed 's|^|/dev/|')
esp=${parts[0]} boot=${parts[1]} root=${parts[2]}
[[ -b $esp && -b $boot && -b $root ]] || die "could not resolve partitions on $disk"

# --- 2. format ESP + /boot ---------------------------------------------------
info "formatting ESP + /boot"
mkfs.vfat -F32 -n EFI-SYSTEM "$esp"
mkfs.ext4 -F -L boot "$boot"

# --- 3. LUKS2 on root (passphrase via stdin, never the process table) --------
info "setting up LUKS2 on $root"
printf '%s' "$passphrase" | cryptsetup luksFormat --batch-mode --type luks2 --key-file - "$root"
printf '%s' "$passphrase" | cryptsetup luksOpen --key-file - "$root" "$mapper"
luks_uuid=$(cryptsetup luksUUID "$root")
[[ -n $luks_uuid ]] || die "could not read LUKS UUID"

# --- 4. format root fs + 5. mount --------------------------------------------
info "formatting + mounting root (xfs)"
mkfs.xfs -f -L root "/dev/mapper/$mapper"
mkdir -p "$mnt"
mount "/dev/mapper/$mapper" "$mnt"
mkdir -p "$mnt/boot"; mount "$boot" "$mnt/boot"
mkdir -p "$mnt/boot/efi"; mount "$esp" "$mnt/boot/efi"

# --- 6. bootc install to-filesystem into the open mapper ---------------------
# Native "bootcDirect" install (NOT `podman run <image> bootc install`): read the
# source straight from containers-storage via --source-imgref. bootc writes layers
# directly into $mnt without materializing a container rootfs, which avoids the
# overlay-on-overlay explosion a podman run hits in the live env's overlayfs root.
# (adapted from projectbluefin/fisherman + dakota-iso bootcDirect path, GPL-3.0)
info "running bootc install to-filesystem from $image (native --source-imgref)"
# bootc imports blobs into $TMPDIR (default /var/tmp) — on the live env that's the
# small 8 GiB overlay tmpfs, which a multi-GB image overflows ("no space left on
# device"). Point it at the target disk instead. bootc also verifies the rootfs is
# empty (only mountpoints), so a plain dir under $mnt fails; self-bind-mount the
# scratch so it counts as a mountpoint while still living on the roomy target fs.
# NB: NOT --generic-image — that makes bootupd install every bootloader component
# (incl. i386-pc BIOS grub, which needs a bios_grub partition we don't create).
# Omitting it makes bootupd run `--auto`, targeting only this machine's firmware
# (UEFI) and registering the EFI boot entry. (bootc bootloader.rs install_via_bootupd)
#
# --skip-finalize: bootc's own finalize step remounts $mnt read-only as its last
# action, then still tries to clean up its internal tempdir — which lives under
# $TMPDIR=$scratch, a bind mount of the SAME superblock as $mnt. Once root goes
# read-only the whole superblock does too (bind mounts don't get an independent
# writable superblock), so that cleanup fails with EROFS ("Installing to
# filesystem: Read-only file system (os error 30)") right after "Finalizing
# filesystem root". We skip bootc's finalize and do our own fstrim+umount below
# (steps 7-8), after unmounting the scratch bind mount, which flushes writeback
# the same way without racing our own tmpdir.
scratch="$mnt/bootc-tmp"
mkdir -p "$scratch"; mount --bind "$scratch" "$scratch"
TMPDIR="$scratch" bootc install to-filesystem \
	--source-imgref "containers-storage:$image" \
	--skip-fetch-check \
	--skip-finalize \
	"$mnt"
umount "$scratch"; rmdir "$scratch" 2>/dev/null || true

# --- 7. inject the LUKS unlock karg into the BLS entries ---------------------
info "wiring LUKS unlock karg (rd.luks.name=$luks_uuid=root)"
inject_luks_arg "$mnt/boot/loader/entries" "$luks_uuid" \
	|| inject_luks_arg "$mnt/boot/efi/loader/entries" "$luks_uuid" \
	|| die "no BLS entries found to patch (bootc install may have failed)"

# --- 8. finalize + cleanup ---------------------------------------------------
info "finalizing"
fstrim --quiet-unsupported -v "$mnt" || true
umount "$mnt/boot/efi" "$mnt/boot" "$mnt"
cryptsetup luksClose "$mapper"

info "done — remove the installer media and reboot into $disk"
