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
"$PODMAN" run --rm -i --no-hostname --platform linux/arm64 "$img" bash -s <<'PROBE'
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
for f in bcm2712-rpi-5-b bcm2712-d-rpi-5-b bcm2712d0-rpi-5-b; do
  grep -qa 'pci1de4,1' "$fw/$f.dtb" 2>/dev/null \
    && ok "$f.dtb is the mainline DTB (RP1 present — USB + Ethernet work)" \
    || bad "$f.dtb is the DOWNSTREAM DTB — the mainline kernel will boot with NO USB and NO Ethernet"
  grep -qa 'bcm2712d0-pinctrl' "$fw/$f.dtb" 2>/dev/null \
    && ok "$f.dtb is the D0 stepping variant" \
    || bad "$f.dtb is not D0 — a Pi 5 Rev 1.1 panics with an SError in brcmstb_pull_config_set"
done
grep -qa 'pcie@1000110000' "$fw/bcm2712-rpi-5-b.dtb" 2>/dev/null \
  && ok "PCIe1 (M.2 slot) described in the DTB — the NVMe will enumerate" \
  || bad "no pcie1 node in the DTB — the NVMe may not appear"
grep -q '^dtoverlay=vc4-kms-v3d-pi5' "$fw/config.txt" 2>/dev/null \
  && bad "downstream vc4 overlay still in config.txt — it cannot apply to a mainline DTB" \
  || ok "no downstream overlays left in config.txt"

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
u=core
getent passwd $u >/dev/null && ok "$u user present" || bad "$u user MISSING"
id -nG $u 2>/dev/null | grep -qw wheel && ok "$u in wheel" || bad "$u NOT in wheel"
grep -q "^$u .*NOPASSWD" /etc/sudoers.d/$u 2>/dev/null && ok "$u has passwordless sudo" || bad "$u cannot sudo — it has no password to type"
case "$(getent shadow $u 2>/dev/null | cut -d: -f2)" in
  "!"*) ok "$u password locked (SSH key only, as intended)";;
  "")   bad "$u has an EMPTY password — that is 'no password required', not 'locked'";;
  *)    bad "$u has a password hash — this image is meant to be key-only";;
esac
[ -s /usr/share/ssh/$u.keys ] && ok "SSH key baked in for $u" || bad "no key in /usr/share/ssh/$u.keys — with no password, THIS IMAGE CANNOT BE LOGGED INTO"
grep -q '^AuthorizedKeysFile /usr/share/ssh/%u.keys' /etc/ssh/sshd_config.d/*.conf 2>/dev/null && ok "sshd reads /usr/share/ssh/%u.keys" || bad "sshd is not configured to read the baked-in key"
grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config.d/*.conf 2>/dev/null && ok "password auth disabled" || bad "password auth still enabled"

sep "hostname / DHCP"
# --no-hostname on the run below is what makes this readable: podman bind-mounts
# a generated /etc/hostname over the path otherwise, and we would be inspecting
# the mount (a container ID) instead of the image.
h=$(cat /etc/hostname 2>/dev/null || true)
case "$h" in
  ""|"localhost"|"fedora") bad "/etc/hostname is '$h' — the device gets no name and its DHCP lease shows '*'";;
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])
       bad "/etc/hostname is '$h' — that is podman's container ID, not a hostname (is --no-hostname set?)";;
  *)       ok "hostname: $h";;
esac

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
  grep -q max_host_mem_size_mb /usr/lib/bootc/kargs.d/*.toml 2>/dev/null && ok "NVMe HMB cap raised (DRAM-less drives stall without it)" || bad "nvme.max_host_mem_size_mb MISSING — a DRAM-less NVMe will lock up under sustained IO"
  kver=$(ls /usr/lib/modules | head -1)
  find "/usr/lib/modules/$kver" -name "ceph.ko*" -print -quit | grep -q . && ok "kernel ceph.ko present" || bad "ceph.ko MISSING — no kernel CephFS mounts"
  [ -d /etc/ceph ] && ok "/etc/ceph present (cephadm writes ceph.conf + keyring here)" || bad "/etc/ceph MISSING"
  if grep -q 'service_type: osd' /etc/ceph/cluster.yaml 2>/dev/null; then
    ok "/etc/ceph/cluster.yaml present (ceph orch apply -i deploys the cluster)"
  else
    bad "/etc/ceph/cluster.yaml MISSING or incomplete"
  fi
  # cephadm SSHes as root by default and this image has no root login, so the
  # non-root path is mandatory: it connects as core and sudo's every command.
  grep -rqs 'NOPASSWD' /etc/sudoers.d/ \
    && ok "passwordless sudo present (required by 'cephadm bootstrap --ssh-user core')" \
    || bad "no NOPASSWD sudoers — cephadm --ssh-user will refuse to bootstrap"
  if rpm -q container-selinux >/dev/null 2>&1; then
    ok "container-selinux present (podman bind-mounts under enforcing)"
  else
    bad "container-selinux missing — expect AVC denials from the Ceph containers"
  fi
else
  echo "(base image — no ceph tooling, as expected)"
fi

sep "s3-versity flavor"
quadlet=/usr/share/containers/systemd/s3.container
if [ -e "$quadlet" ]; then
  # Quadlet units are generated at boot into /run, so there is no file to enable
  # and no .wants symlink to check — [Install] inside the quadlet IS the switch.
  grep -q '^\[Install\]' "$quadlet" \
    && ok "s3.container has [Install] (Quadlet enables it at boot)" \
    || bad "s3.container has NO [Install] — the S3 server would never start at boot"
  grep -q '^Image=.*versitygw:v' "$quadlet" \
    && ok "gateway image pinned to a version tag (never :latest on an appliance)" \
    || bad "s3.container does not pin a versitygw version tag"
  grep -q 'minio' "$quadlet" \
    && bad "s3.container still references MinIO — its upstream is archived, see README" \
    || ok "not MinIO (archived upstream) — using the maintained versitygw"
  grep -q '^Requires=var-lib-s3.mount' "$quadlet" \
    && ok "s3.service requires the NVMe mount (cannot fill the SD card instead)" \
    || bad "s3.container does not Require= the mount — objects could land on the boot media"
  grep -q ':/srv:z' "$quadlet" \
    && ok "data volume relabelled :z (stable SELinux label, no relabel storm on restart)" \
    || bad "data volume is not :z — expect AVC denials or a full relabel on every start"
  # versitygw only parses global flags BEFORE the backend subcommand.
  grep -q '^Exec=.*--iam-dir .* posix ' "$quadlet" \
    && ok "global flags precede the 'posix' subcommand (versitygw needs this order)" \
    || bad "a global flag sits after 'posix' — versitygw exits with a usage error at boot"
  [ -x /usr/lib/systemd/system-generators/podman-system-generator ] \
    && ok "podman Quadlet generator present" \
    || bad "podman-system-generator MISSING — every .container file is ignored"
  for u in var-lib-s3.mount s3-format.service; do
    [ -e "/usr/lib/systemd/system/$u" ] && ok "$u shipped" || bad "$u MISSING"
  done
  # The format step is the one that can destroy data, so check both halves of it.
  grep -q '^ExecStart=/usr/lib/systemd/systemd-makefs xfs' /usr/lib/systemd/system/s3-format.service \
    && ok "format uses systemd-makefs (no-ops on a disk that already has a filesystem)" \
    || bad "s3-format.service does not use systemd-makefs — it may reformat on every boot"
  grep -q '^ExecCondition=.*blkid.*PTTYPE' /usr/lib/systemd/system/s3-format.service \
    && ok "format refuses a partitioned disk (systemd-makefs alone would not)" \
    || bad "no partition-table guard — an OS disk in the M.2 slot would be WIPED"
  [ -x /usr/lib/systemd/systemd-makefs ] && ok "systemd-makefs binary present" || bad "/usr/lib/systemd/systemd-makefs MISSING — the NVMe will never be formatted"
  command -v mkfs.xfs >/dev/null 2>&1 && ok "mkfs.xfs (xfsprogs)" || bad "mkfs.xfs MISSING — systemd-makefs cannot format anything"
  command -v getfattr >/dev/null 2>&1 && ok "getfattr (object metadata lives in xattrs)" || bad "attr MISSING — you cannot inspect or back up object metadata"
  [ -x /usr/libexec/s3-setup ] && ok "setup/credential script present" || bad "/usr/libexec/s3-setup MISSING"
  [ -e /etc/s3/root.env ] \
    && bad "SECRET BAKED INTO THE IMAGE: /etc/s3/root.env must be generated on the device" \
    || ok "no credentials in the image (minted on first start)"
else
  echo "(no s3 quadlet — as expected unless this is the s3 image)"
fi


sep "s3-garage flavor"
gq=/usr/share/containers/systemd/garage.container
if [ -e "$gq" ]; then
  # Quadlet units are generated at boot into /run, so there is no file to enable
  # and no .wants symlink to check — [Install] inside the quadlet IS the switch.
  grep -q '^\[Install\]' "$gq" \
    && ok "garage.container has [Install] (Quadlet enables it at boot)" \
    || bad "garage.container has NO [Install] — Garage would never start at boot"
  grep -q '^Image=.*dxflrs/garage:v' "$gq" \
    && ok "Garage image pinned to a version tag (upstream asks for this explicitly)" \
    || bad "garage.container does not pin a dxflrs/garage version tag"
  # v2.2.0 fixed a SIGILL crash on Raspberry Pi / older ARM; earlier tags die here.
  gv=$(sed -n 's/^Image=.*garage:v\([0-9]*\)\.\([0-9]*\).*/\1 \2/p' "$gq")
  set -- $gv
  if [ "${1:-0}" -gt 2 ] || { [ "${1:-0}" -eq 2 ] && [ "${2:-0}" -ge 3 ]; }; then
    ok "Garage >= v2.3 (has --single-node; and >= v2.2 fixed the Pi SIGILL crash)"
  else
    bad "Garage v${1:-?}.${2:-?} is too old — v2.2 fixed a SIGILL on the Pi and v2.3 added --single-node"
  fi
  # The image is FROM scratch with a CMD and no ENTRYPOINT: args REPLACE the
  # command, so the binary path has to be spelled out or nothing runs.
  grep -q '^Exec=/garage server' "$gq" \
    && ok "Exec= names the /garage binary (the image has no ENTRYPOINT)" \
    || bad "Exec= does not start with /garage — args replace the CMD, so the container would run nothing"
  grep -q -- '--single-node' "$gq" \
    && ok "--single-node (auto-creates and applies the cluster layout)" \
    || bad "no --single-node — the node would boot with NO ROLE and serve nothing"
  grep -q '^Requires=var-lib-garage.mount' "$gq" \
    && ok "garage.service requires the NVMe mount (cannot fill the SD card instead)" \
    || bad "garage.container does not Require= the mount — objects could land on the boot media"
  grep -q '^Volume=/var/lib/garage:/var/lib/garage:z' "$gq" \
    && ok "data volume relabelled :z (stable SELinux label, no relabel storm on restart)" \
    || bad "data volume is not :z — expect AVC denials or a full relabel on every start"
  [ -x /usr/lib/systemd/system-generators/podman-system-generator ] \
    && ok "podman Quadlet generator present" \
    || bad "podman-system-generator MISSING — every .container file is ignored"
  for u in var-lib-garage.mount garage-format.service; do
    [ -e "/usr/lib/systemd/system/$u" ] && ok "$u shipped" || bad "$u MISSING"
  done
  # The format step is the one that can destroy data, so check both halves of it.
  grep -q '^ExecStart=/usr/lib/systemd/systemd-makefs xfs' /usr/lib/systemd/system/garage-format.service \
    && ok "format uses systemd-makefs (no-ops on a disk that already has a filesystem)" \
    || bad "garage-format.service does not use systemd-makefs — it may reformat on every boot"
  grep -q '^ExecCondition=.*blkid.*PTTYPE' /usr/lib/systemd/system/garage-format.service \
    && ok "format refuses a partitioned disk (systemd-makefs alone would not)" \
    || bad "no partition-table guard — an OS disk in the M.2 slot would be WIPED"
  [ -x /usr/lib/systemd/systemd-makefs ] && ok "systemd-makefs binary present" || bad "/usr/lib/systemd/systemd-makefs MISSING — the NVMe will never be formatted"
  command -v mkfs.xfs >/dev/null 2>&1 && ok "mkfs.xfs (xfsprogs; XFS is what Garage recommends for the data dir)" || bad "mkfs.xfs MISSING — systemd-makefs cannot format anything"
  # Config and setup script must agree on the paths, or Garage exits at startup.
  if [ -f /etc/garage.toml ]; then
    ok "/etc/garage.toml shipped"
    grep -q '^db_engine *= *"sqlite"' /etc/garage.toml \
      && ok "db_engine = sqlite (LMDB corrupts on power loss and RF=1 has no replica to heal from)" \
      || bad "db_engine is not sqlite — an unplugged Pi can corrupt the metadata DB beyond recovery"
    grep -q '^replication_factor *= *1' /etc/garage.toml \
      && ok "replication_factor = 1 (the only valid value for one node)" \
      || bad "replication_factor is not 1 — a single node cannot satisfy a higher factor"
    for d in /var/lib/garage/meta /var/lib/garage/data; do
      grep -q "\"$d\"" /etc/garage.toml && ok "config points at $d" || bad "$d not in garage.toml — it and garage-setup have drifted"
    done
    grep -qE '^ *(rpc_secret|admin_token|metrics_token) *=' /etc/garage.toml \
      && bad "SECRET BAKED INTO THE IMAGE: garage.toml sets a secret inline" \
      || ok "no secrets in garage.toml (generated on the device)"
  else
    bad "/etc/garage.toml MISSING — Garage has no config and will not start"
  fi
  [ -x /usr/libexec/garage-setup ] && ok "setup/credential script present" || bad "/usr/libexec/garage-setup MISSING"
  [ -x /usr/bin/garage ] && ok "garage CLI wrapper present" || bad "/usr/bin/garage MISSING — no way to run 'garage status'"
  command -v aws >/dev/null 2>&1 && ok "aws CLI (smoke-test the endpoint from the box)" || bad "awscli2 MISSING"
  [ -e /etc/garage/env ] \
    && bad "SECRETS BAKED INTO THE IMAGE: /etc/garage/env must be generated on the device" \
    || ok "no credentials in the image (minted on first start)"
else
  echo "(no garage quadlet — as expected unless this is the s3-garage image)"
fi
sep "size"
du -sh /usr 2>/dev/null | cut -f1
PROBE
