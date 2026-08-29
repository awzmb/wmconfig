#!/usr/bin/env bash
#
# configure.sh — cephfs flavor configuration, run by the Containerfile after the
# packages and overlay are in place.
#
# Nothing here is cluster-specific: an image can't know your fsid, mons or keys.
# It only makes the node a valid cephadm host (time sync, LVM, /etc/ceph) so that
# `cephadm bootstrap` / `ceph orch host add` work out of the box.
set -euo pipefail

info() { printf '\e[1;32m-->\e[0m\e[1m %s\e[0m\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }

# Same static /usr enablement as the base layer: `systemctl enable` does not
# survive an offline image build.
enable_unit() {
	local unit=$1 target=${2:-multi-user.target} src="" d
	for d in /etc/systemd/system /usr/lib/systemd/system; do
		[[ -e $d/$unit ]] && { src=$d/$unit; break; }
	done
	[[ -n $src ]] || { warn "unit $unit not found; NOT enabled (package missing?)"; return; }
	mkdir -p "/usr/lib/systemd/system/${target}.wants"
	ln -sfn "$src" "/usr/lib/systemd/system/${target}.wants/$unit"
}

# --- The external PCIe port (the NVMe carrying the OSD) ------------------
# Nothing to do: the base layer puts the KERNEL's mainline DTB on the ESP (see
# images/base/scripts/configure.sh), and mainline's bcm2712-rpi-5-b-base.dtsi already
# sets pcie1 — the M.2 slot — to "okay".
#
# `dtparam=pciex1` is deliberately NOT written here. dtparams are applied by the
# firmware through the DTB's `__overrides__` node, which only the DOWNSTREAM DTBs
# carry; against a mainline DTB every dtparam is a silent no-op. Adding one back
# would look like it enabled PCIe while doing nothing at all.
# ponytail: Gen 2 (the mainline default). Gen 3 roughly doubles NVMe throughput
# but is out of spec, and this node's ceiling is the 1 GbE NIC anyway.

# --- NVMe Host Memory Buffer ---------------------------------------------
# DRAM-less NVMe drives (Samsung 990 EVO, most modern budget/mid drives) keep
# their flash translation layer in HOST RAM via HMB. The Pi 5 caps HMB at 32 MiB,
# but these drives ask for 64 MiB — and when the request exceeds the cap the
# kernel does not shrink it, it disables HMB ALTOGETHER:
#     nvme nvme0: min host memory (64 MiB) above limit (32 MiB)
# The drive then thrashes its FTL, which shows up as stalls, IO timeouts and hard
# lockups under sustained writes. That is exactly a Ceph OSD's workload, so raise
# the cap. 128 MiB covers every current consumer drive and is noise on a 16 GB Pi.
#
# NOTE: on Raspberry Pi OS this goes in cmdline.txt — that file is NOT used here.
# We boot EEPROM -> U-Boot -> GRUB -> BLS, so the kernel command line comes from
# bootc's kargs.d, which `bootc install` bakes into the BLS entry.
info "Raising the NVMe HMB cap (DRAM-less drives stall without it)"
mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/20-nvme-hmb.toml <<'EOF'
# DRAM-less NVMe drives need more Host Memory Buffer than the Pi 5's 32 MiB
# default; exceeding the cap makes the kernel disable HMB entirely, which causes
# IO stalls and lockups under sustained load. 128 MiB covers current drives.
kargs = ["nvme.max_host_mem_size_mb=128"]
EOF

# --- Time synchronisation (a HARD Ceph requirement) ----------------------
# Monitors refuse to form a quorum on clock skew (>50ms warns, >600ms is fatal),
# and the Pi 5 has no RTC — it boots at the epoch until chrony corrects it.
info "Enabling chronyd (Ceph monitors will not tolerate clock skew)"
enable_unit chronyd.service

# --- LVM ------------------------------------------------------------------
# ceph-volume carves OSDs out of LVM; dmeventd monitors those LVs.
enable_unit lvm2-monitor.service

# --- /etc/ceph ------------------------------------------------------------
# cephadm bootstrap writes ceph.conf + the admin keyring here. /etc is preserved
# across bootc upgrades, so cluster identity survives a `fedora-update`.
install -d -m 0755 /etc/ceph

# --- Kernel CephFS client -------------------------------------------------
# `mount -t ceph` autoloads the ceph module (and libceph), so nothing is
# preloaded here. Verify the modules actually shipped with this kernel — a
# CephFS node with no ceph.ko is a silent, boot-time-only discovery otherwise.
for kver in /usr/lib/modules/*/; do
	kver=$(basename "$kver")
	[[ -e /usr/lib/modules/$kver/kernel ]] || continue
	for m in ceph libceph rbd; do
		find "/usr/lib/modules/$kver" -name "$m.ko*" -print -quit | grep -q . \
			|| warn "kernel module $m missing from $kver — kernel CephFS/RBD mounts will not work"
	done
done

# --- Sanity checks --------------------------------------------------------
for chk in \
	"cephadm:/usr/sbin/cephadm" \
	"mount.ceph:/usr/sbin/mount.ceph" \
	"ceph CLI:/usr/bin/ceph" \
	"chronyd:/usr/sbin/chronyd" \
	"ceph-volume needs lvm:/usr/sbin/lvm" \
	"nvme-cli:/usr/sbin/nvme"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || warn "MISSING: $name ($path) — check the install log above"
done

# cephadm shells out to podman for every daemon; without it the node is inert.
command -v podman >/dev/null 2>&1 || warn "podman missing — cephadm cannot run any Ceph daemon"

info "cephfs flavor configure complete"
