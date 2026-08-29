# AGENTS.md

Guidance for AI agents working in this repo.

## What this is

Scripts that build a **minimal Fedora bootc (image-mode) OS for a Raspberry Pi 5
(aarch64, headless appliance)**, turn it into a raw disk image for an SD card /
NVMe, and update an installed system in place. **A minimal base image plus thin
optional flavor layers** — the old multi-flavor desktop tree (gnome/gnome-sway/
kde/hyprland, LUKS + tacklebox live installer) has been removed.

## Layout

```
fedora-build      # podman build -> localhost/fedora-rpi5[-<flavor>]:latest (linux/arm64)
fedora-image      # osbuild image-builder -> raw disk image + flash to SD/NVMe
fedora-update     # day-2: rebuild ON the Pi + `bootc switch`/`upgrade` for next boot
test.sh           # read-only pre-flight inspection of a built image
images/
├── base/                     # the BASE layer, built by `./fedora-build`
│   ├── Containerfile         # FROM fedora-bootc + ONE build RUN
│   ├── package.list          # packages to layer (deliberately short)
│   ├── authorized_keys       # OPTIONAL, untracked: SSH key (--ssh-key is preferred)
│   ├── overlay/              # rootfs overlay, cp -a'd onto /
│   └── scripts/configure.sh  # Pi firmware relocation, user, services, kargs
├── cephfs/                   # FROM the base: Ceph storage node (NVMe = OSD)
│   ├── Containerfile         # FROM localhost/fedora-rpi5:latest
│   ├── package.list          # cephadm, ceph-common, ceph-fuse, lvm2, chrony, nvme-cli
│   ├── overlay/              # /etc/sysctl.d/90-ceph.conf, /etc/ceph/cluster.yaml
│   └── scripts/configure.sh  # chronyd + lvm2-monitor, /etc/ceph, module checks
├── s3-versity/               # FROM the base: versitygw S3 gateway (NVMe = objects)
│   ├── Containerfile         # FROM localhost/fedora-rpi5:latest
│   ├── package.list          # xfsprogs (REQUIRED), attr, util-linux, nvme-cli, smartmontools
│   ├── overlay/              # s3.container Quadlet, var-lib-s3.mount, format unit
│   └── scripts/configure.sh  # build-time sanity checks only; nothing to enable
└── s3-garage/                # FROM the base: Garage object store (NVMe = objects)
    ├── Containerfile         # FROM localhost/fedora-rpi5:latest
    ├── package.list          # xfsprogs (REQUIRED), util-linux, nvme-cli, awscli2
    ├── overlay/              # garage.container Quadlet, garage.toml, mount + format units
    └── scripts/configure.sh  # build-time sanity checks only; nothing to enable
```

## Build / test

```sh
sudo ./fedora-build                        # base image (prompts for hostname + key)
sudo ./fedora-build cephfs                 # base + the cephfs layer
sudo ./fedora-build s3-versity             # base + the versitygw S3 layer
sudo ./fedora-build s3-garage              # base + the Garage S3 layer
# the full non-interactive form — this is the one to reach for:
sudo ./fedora-build cephfs --hostname cephfs01 --ssh-key ~/.ssh/id_ed25519.pub
FEDORA_SKIP_BASE=1 sudo ./fedora-build cephfs   # reuse the base (fast iteration)
# NB: hostname/key are baked into the BASE layer, so --hostname with
# FEDORA_SKIP_BASE=1 silently changes nothing.
sudo ./test.sh [image]                     # inspect it (no boot needed)
sudo ./fedora-image [flavor]               # raw disk image into ./target
sudo ./fedora-image cephfs --device /dev/mmcblk0  # ...and flash it (DESTRUCTIVE)
sudo ./fedora-update [flavor] [--apply]    # day-2, run on the Pi
bash -n <script>                           # syntax-check a changed shell script
```

Tag convention, shared by all three scripts: `localhost/fedora-rpi5[-<flavor>]:latest`.
Overrides: `FEDORA_BASE` (the `FROM`, via `--build-arg BASE`), `FEDORA_TAG`,
`FEDORA_BASE_TAG`, `FEDORA_SKIP_BASE`, `FEDORA_PLATFORM`, `FEDORA_IMAGE_BUILDER`,
`PODMAN`. There is no test suite; a real build needs podman, network and pulls a
multi-GB base, so it can't run in a lightweight sandbox — validate shell changes
with `bash -n` and reason about the Containerfiles.

## Key facts / gotchas

- **Target is aarch64.** `fedora-build` always passes `--platform linux/arm64`.
  On an x86_64 host that is a `qemu-user-static`/binfmt cross-build (~10x slower);
  the script warns when no `qemu-aarch64` binfmt handler is registered. Building
  on the Pi itself is the fast path, and `fedora-update` relies on that.
- **The Pi 5 has NO UEFI.** Boot chain: BCM2712 EEPROM → `config.txt` →
  `rpi-u-boot.bin` (U-Boot supplies the EFI environment) → GRUB2-EFI → BLS entry
  → kernel. Tianocore/edk2 has no RPi5 platform and `worproject/rpi5-uefi` is
  archived — do NOT reach for a UEFI path.
- **Pi firmware must be relocated out of `/boot/efi` at build time.**
  `bcm283x-firmware` / `bcm283x-overlays` / `uboot-images-armv8` install into
  `/boot/efi`, which a bootc image may not own (`bootc container lint` and
  `bootc install` both object). `configure.sh` copies them to
  `/usr/lib/bootc-rpi-firmware/` (U-Boot renamed `rpi-u-boot.bin`), then
  `dnf remove`s the packages and deletes `/boot/efi`. The three packages are
  BUILD-TIME ONLY — they are in `package.list` but not in the final image.
- **The rootfs grows to fill the card on first boot, but ONLY because of our
  drop-in.** fedora-bootc ships `bootc-generic-growpart.service` (statically
  enabled from `local-fs.target.wants` by the base-image build, not by the bootc
  RPM) which runs `growpart` + `systemd-growfs /sysroot`. It is guarded by
  `ConditionVirtualization=vm`, so on a Raspberry Pi — bare metal — it is
  SKIPPED and the root filesystem stays at the image's ~8.5 GiB regardless of
  card size. `images/base/overlay/.../bootc-generic-growpart.service.d/10-grow-on-bare-metal.conf`
  resets that condition (an empty assignment clears a condition list), and
  `cloud-utils-growpart` is in `package.list` because the unit also requires
  `ConditionPathExists=/usr/bin/growpart`. All three pieces are needed; drop any
  one and the card silently stays small. `configure.sh` warns and `test.sh`
  checks. Verify on the device with `systemd-detect-virt` (expect `none`) and
  `systemctl status bootc-generic-growpart.service`.
- **`bootupctl` is shimmed on purpose.** bootupd has no Raspberry Pi support
  (coreos/bootupd#766), so nothing would ever put the firmware on the ESP.
  `configure.sh` moves the real binary to `/usr/libexec/bootupd-orig/bootupctl`
  and installs a shell wrapper that, on `bootupctl backend install`, copies
  `/usr/lib/bootc-rpi-firmware/.` onto the ESP after delegating (see the next
  bullet for why the order matters). This
  is what makes both `fedora-image` (image-builder) and a manual `bootc install`
  produce a bootable card. Consequence: **the ESP firmware never updates on day 2**
  — `fedora-update` only replaces the OS; re-flash to move U-Boot/firmware.
- **The shim must run bootupd FIRST and copy the firmware AFTERWARDS.** `bootc`
  bind-mounts the physical `/boot` into its chroot NON-recursively on purpose, so
  that `<chroot>/boot/efi` is an EMPTY directory which bootupd's EFI component can
  mount the real ESP onto itself (`bootloader.rs`, `MountedImageRoot::with_esp()`).
  Copying there before bootupd runs writes the files UNDER a mountpoint — they are
  shadowed, then stranded on the `/boot` filesystem, and the ESP ends up holding
  nothing but `EFI/`. The card then never boots and NOTHING in the build log says
  so. After bootupd returns, the shim locates the ESP as the first of
  `/sysroot/boot/efi` (the physical root, bind-mounted recursively when
  `--filesystem` is used), `<dest>/boot/efi`, `/boot/efi` that contains an `EFI/`
  directory, and **exits non-zero if it finds none** — a loud build failure beats a
  silently unbootable card. bootc's `backend install --help` probe is passed
  straight through. The copy uses `cp -rL`, never `cp -a`: the ESP is FAT32,
  which supports neither hard links nor symlinks, and Fedora's firmware set
  contains hardlinked pairs (`fixup_cd.dat`/`fixup4cd.dat`) that make `cp -a`
  fail with EPERM.
- **The stashed real binary MUST keep the basename `bootupctl`** — hence the
  `bootupd-orig/` directory rather than a `bootupctl-real` rename. bootupd is a
  MULTICALL binary: `src/cli/mod.rs` selects its verb set from `argv[0]`
  (`bootupctl` → the ctl verbs, which include the hidden `backend`; anything else
  → the daemon verbs, which do not). Rename the file and `bootc install` dies with
  `error: unrecognized subcommand 'backend'` while probing
  `bootupctl backend install --help`. `test.sh` runs that exact probe.
- **`image-builder`, not `bootc-image-builder`.** `osbuild/bootc-image-builder`
  was merged into `osbuild/image-builder` and archived; `fedora-image` uses
  `ghcr.io/osbuild/image-builder-cli` with `build --bootc-ref <img>
  --bootc-default-fs ext4 raw`, plus `--arch aarch64` when the host isn't
  aarch64. ext4 (not the xfs default) because every Pi recovery tool speaks ext4.
- **The Containerfile is ONE `RUN` over a bind-mounted context** (no `COPY`), so
  no build cruft (dnf cache, logs, the context dir) is baked in — deleting files
  in a *later* layer does NOT reclaim space, so install + overlay + configure +
  cleanup must share one RUN. The install passes
  `--setopt=install_weak_deps=False --skip-unavailable --skip-broken`; a missing
  package is a warning, not a build failure, so `configure.sh` re-checks critical
  paths (NetworkManager, sshd, the Pi firmware, brcmfmac) at the end and warns
  loudly.
- **podman does NOT hash the bind-mounted context**, so editing `scripts/`,
  `package.list` or `overlay/` would reuse the cached (stale) RUN layer.
  `fedora-build` passes `--build-arg CACHEBUST=<content-hash>` (`ctx_hash`),
  which the RUN references (`: "cachebust ${CACHEBUST}"`). Keep both halves.
- **No initramfs regeneration.** The stock generic initramfs from the
  `fedora-bootc` base already contains `ostree` and the storage drivers. The old
  tree regenerated it only for LUKS and for keeping GPU drivers out — both gone.
  Do not reintroduce a dracut regen without a concrete boot failure to fix; if
  you do, `--add ostree` is mandatory or the composefs root cannot mount.
- **No disk encryption.** A headless Pi has nobody to type a passphrase and no
  TPM. The entire LUKS story (dracut `parse-crypt.sh` backslash patch,
  `rd.luks.*` kargs, `force_drivers=nvme`, the live installer) was deleted with
  it. If encryption is ever needed, it needs a network-unlock story
  (clevis/tang), not a passphrase prompt.
- **Serial console is baked in** (`console=tty1 console=ttyAMA0,115200` via
  `/usr/lib/bootc/kargs.d/10-console.toml`) because Pi 5 HDMI support in the
  generic Fedora kernel is unreliable — the UART header is often the only way to
  see an early boot failure. Keep the serial console LAST so it owns `/dev/console`.
- **Access is SSH-key-only; there is no password anywhere.** The `core` user is
  created at BUILD TIME (`configure.sh`), not by an installer, so it works under
  any install path, and its password is LOCKED (`passwd -l` — an empty hash would
  mean "no password required", which is the opposite of what we want). Because a
  locked account cannot type a sudo password, `/etc/sudoers.d/core` grants
  NOPASSWD, exactly as Fedora CoreOS does. Consequences to keep in mind:
  - **The key lives in `/usr/share/ssh/<user>.keys`, not in the home directory.**
    `/var` (hence `/var/home`) is machine-local state the image stops owning after
    install, so a key written there is easy to lose on reinstall. sshd is pointed
    at the `/usr` path with `AuthorizedKeysFile /usr/share/ssh/%u.keys
    .ssh/authorized_keys` in `/etc/ssh/sshd_config.d/10-headless.conf`.
  - **No key baked in = a brick.** There is no password fallback on the HDMI
    console or the serial header either. `fedora-build` warns loudly and
    `configure.sh` warns again; `test.sh` fails the build check.
  - Hostname, user and key arrive as `--build-arg IMAGE_HOSTNAME/IMAGE_USER/
    IMAGE_SSH_KEY`; `fedora-build` prompts for the first two interactively and
    falls back to `~/.ssh/id_ed25519.pub` (of `$SUDO_USER`, not root).
- **`./fedora-build` must pass `--no-hostname`, or the hostname silently vanishes.**
  podman/buildah bind-mounts a generated `/etc/hostname` (containing the 12-hex
  container ID) over the path for the duration of EVERY `RUN`, so anything
  `configure.sh` writes there — or that the overlay copies there — goes to the
  mount and is discarded when the layer commits. The device then boots with
  `Static hostname: (unset)` and a transient `fedora`. `COPY` is not affected by
  the mount; `--no-hostname` was the smaller change since `configure.sh` already
  had the value. Note the same mount applies to `podman run`, so **`test.sh` runs
  with `--no-hostname` too** — without it, it would inspect the mount and report
  a container ID. Verifying inside the build is pointless: reading back through
  the bind mount succeeds even when the write is being thrown away.
- **DHCP hostname advertisement needs no configuration.** NetworkManager sends
  the **static** hostname (hostnamed's `StaticHostname`, i.e. `/etc/hostname`) and
  never the transient one, and `ipv4.dhcp-send-hostname` already defaults to
  true. So a `*` in the DHCP lease means `/etc/hostname` is empty — fix the
  hostname, not NetworkManager. (An earlier `conf.d/10-dhcp-hostname.conf` was
  deleted as a no-op. If one is ever needed again, note that NM 1.52 renamed the
  key to `dhcp-send-hostname-v2` and *errors out* if the two disagree.)
- **Service enablement is static** (`.wants` symlinks written into `/usr`),
  because `systemctl enable` is unreliable in an offline image build. Same for
  `getty@tty1`, which the container-derived base does not enable (containers have
  no VTs) — without it the HDMI console has no login prompt.
- **Mainline kernel support for BCM2712/RP1 is still incomplete.** HDMI, PCIe/NVMe
  and some peripherals may not work on the generic Fedora aarch64 kernel.
  `copr.fedorainfracloud.org/coprs/pbrobinson/a64-kernel/` is the fallback.
- **Keep `package.list` short.** This is an appliance. The `fedora-bootc` base
  already ships systemd, dnf, bootc, coreutils, vim-minimal and openssh-clients;
  only add what it does not. No RPM Fusion, no Tailscale, no third-party repos —
  `setup-repos.sh` is gone; re-adding a repo means re-adding network-fetch
  failure modes to the build.

## The `cephfs` flavor

- **No Ceph daemon RPMs are installed** (`ceph-mon`/`ceph-osd`/`ceph-mgr`/
  `ceph-mds`). `cephadm` runs the daemons as podman containers from
  `quay.io/ceph/ceph` (multi-arch, arm64 present since v17) — the upstream path,
  and it decouples the cluster version from Fedora's `ceph` RPM cadence. The host
  only needs `cephadm` + `ceph-common` (CLI + `/usr/bin/mount.ceph`) + `lvm2` +
  `python3` + `openssh-server` + podman, which is exactly cephadm's documented
  requirement set. Don't "helpfully" add the daemon packages. A consequence worth
  knowing before someone "fixes" it: on a freshly booted node `systemctl status
  ceph-osd` finds nothing and never will — cephadm names its units
  `ceph-<fsid>@osd.0.service` and only creates them once a cluster exists. The
  `ceph.target`/`ceph-crash.service` visible on a fresh boot ship with
  `ceph-common` and are not evidence of a problem.
- **`cephadm bootstrap` MUST be run with `--ssh-user core` on this image.**
  cephadm SSHes to every host as `root` by default; this image sets
  `PermitRootLogin no` and has no root password, so the default path can never
  work. With `--ssh-user` it connects as that user and prefixes `sudo` to every
  remote command (`use_sudo = (ssh_user != 'root')` in the mgr's `ssh.py`), which
  requires **passwordless sudo** — bootstrap self-checks it by running literally
  `ssh core@host 'sudo echo'` and aborts with "must have passwordless sudo
  access" if it fails. Our `/etc/sudoers.d/core` is byte-for-byte the file
  cephadm's own `setup_sudoers()` would write, so nothing else is needed. Never
  add `Defaults requiretty` to this image; it breaks that check.
- **Cluster layout lives in `/etc/ceph/cluster.yaml`** (shipped by the flavor
  overlay), a cephadm service spec applied with `ceph orch apply -i`. This repo
  deliberately has **no wrapper script** around cluster creation: `--apply-spec`/
  `orch apply` is cephadm's own declarative, idempotent automation, and adding a
  second (or third) node is the same file plus the same command. Do not grow a
  bespoke provisioning tool here.
- **A spec cannot create a filesystem.** `service_type: mds` only *places*
  daemons; the pools and the fs come from `ceph fs volume create <name>
  --placement=...`, which creates the metadata+data pools AND the MDS daemons in
  one go. Order matters: hosts → OSDs → `fs volume create`.
- **cephadm's SSH key must be authorized on the other node before it can be
  added** — `--apply-spec` does not distribute it. Easiest path with no
  pre-shared private key: pipe it from the workstation, which can already reach
  both (`ssh core@n1 sudo cat /etc/ceph/ceph.pub | ssh core@n2 'mkdir -p -m700
  ~/.ssh && cat >> ~/.ssh/authorized_keys'`). `AuthorizedKeysFile` intentionally
  lists `.ssh/authorized_keys` after `/usr/share/ssh/%u.keys` so this works at
  runtime. Alternatively pre-bake a keypair and pass `--ssh-private-key` /
  `--ssh-public-key`.
- **Two nodes is not a fault-tolerant cluster, and two mons are worse than one.**
  Mon quorum is a strict majority, so with 2 mons losing *either* host freezes
  the control plane — the same outage as 1 mon, at twice the probability. The
  cheap fix is a **third mon on any always-on machine; it needs no OSD and no
  disks**. Also: the CRUSH failure domain is `host`, so 2 hosts cap you at 2
  copies — `size=3` does not create a third copy, it parks the PGs in
  `active+undersized+degraded` forever. Erasure coding needs more hosts, and
  stretch mode is for two datacenters plus a tiebreaker and forces `size=4`;
  neither applies. Don't let anyone "improve" the pool settings into one of
  these.
- **Pin OSD memory by hand on a 16 GB converged node.** cephadm enables
  `osd_memory_target_autotune` at bootstrap, which hands ~70% of RAM to the OSDs
  — on a node that is *also* the mon, mgr and MDS, a lone OSD claims ~11 GB and
  everything else gets squeezed. Set `osd_memory_target_autotune false` +
  `osd_memory_target 4G` and drop `mds_cache_memory_limit` to ~2G.
- **cephadm is fine on a bootc host** — everything it writes is under `/etc`
  (`ceph.conf`, keyring, `ceph.pub`, sudoers, systemd units) or `/var`
  (`/var/lib/ceph/<fsid>`), both writable and persistent. The one thing that will
  NOT work is `cephadm add-repo` / `cephadm install`: those shell out to dnf and
  target read-only `/usr`. That is why the tools are RPMs in the image. Never
  call them at runtime.
- **`container-selinux` is listed explicitly in the base `package.list`.** Weak
  deps are off image-wide, so it is not guaranteed to arrive with podman, and
  without it every Ceph container's bind mount trips SELinux on enforcing.
- **Fedora builds all Ceph packages for aarch64** (the spec's `ExcludeArch` is
  `i686 armv7hl` only). `cephadm`, `ceph-volume`, `ceph-mgr-cephadm` are noarch.
  Only `rbd_rwl_cache`/PMDK are disabled on arm64 — irrelevant for CephFS.
- **chrony is enabled by this layer and is not optional.** The Pi 5 has NO RTC,
  so it boots with a bogus clock; Ceph monitors warn at 50 ms skew and refuse
  quorum well before a whole-epoch offset.
- **`fs.aio-max-nr` / `kernel.pid_max`** are raised in
  `overlay/etc/sysctl.d/90-ceph.conf`. The stock values make BlueStore OSDs fail
  with "aio submit got (11) Resource temporarily unavailable" under load.
- **Nothing cluster-specific is baked into the image** — no fsid, mons, keyrings
  or mount units, because an image can't know them. `cephadm bootstrap` writes
  them into `/etc/ceph`, which is `/etc` and therefore preserved across
  `fedora-update`. Keep it that way; a keyring in the image is a keyring in every
  registry that image is ever pushed to.
- **`nvme.max_host_mem_size_mb=128` is set via `kargs.d`, and it is not optional
  for DRAM-less drives.** The Pi 5 caps NVMe Host Memory Buffer at 32 MiB; drives
  like the Samsung 990 EVO require 64 MiB, and the kernel responds to an
  over-cap request by disabling HMB completely (`min host memory (64 MiB) above
  limit (32 MiB)`), not by shrinking it. The drive then thrashes its FTL and the
  box locks up under sustained writes — i.e. under normal OSD load. Note the
  channel: Raspberry Pi OS puts this in `cmdline.txt`, which this stack does NOT
  use (EEPROM → U-Boot → GRUB → BLS), so it must go through `bootc`'s `kargs.d`.
- **The ESP must carry the KERNEL's mainline DTB, not `bcm283x-firmware`'s.**
  This is the single most load-bearing fact in the repo, because the failure mode
  is invisible: the Pi boots all the way to a login prompt with **no USB and no
  Ethernet**. On a Pi 5 both live behind RP1, and mainline and downstream model
  RP1 incompatibly — mainline embeds it under the PCIe endpoint node
  `dev@0,0 { compatible = "pci1de4,1" }` and `drivers/misc/rp1` populates the USB
  (`snps,dwc3`) and Ethernet (`raspberrypi,rp1-gem`) children from that subtree,
  while downstream models it as a `simple-bus` off `rp1_target`. The driver finds
  no matching OF node, populates nothing, and says nothing. Fedora converts the
  downstream DTB for older boards with `dtoverlay=upstream` / `upstream-pi4`, but
  **there is no `upstream-pi5.dtbo`** and `[pi5]` in Fedora's `config.txt` has no
  equivalent — so the Pi 5 has no escape hatch and `images/base/scripts/configure.sh`
  copies `/usr/lib/modules/*/dtb/broadcom/bcm2712*rpi-5-b.dtb` over the staged
  firmware ones.   Note the stepping: the firmware picks the DTB by file NAME and then converts it
  for D0 silicon by auto-applying `overlays/bcm2712d0.dtbo` — which, being a
  downstream overlay, cannot apply to a mainline DTB. The stepping fixup then
  silently does not happen, the kernel drives C0 pinctrl registers
  (`reg = <0x7d504100 0x30>`) on a D0 chip whose window is only `0x20`, and
  `brcmstb_pull_config_set` takes a bus error while `gpio_keys` probes the power
  button: **`Kernel panic - not syncing: Asynchronous SError Interrupt`** about
  2.7 s in. Mainline ships the stepping as a separate file
  (`bcm2712-d-rpi-5-b.dts`, which only overrides the two pinctrl nodes and the
  AON bank widths), so `configure.sh` picks `pi5_soc=bcm2712-d-rpi-5-b` and
  writes it under **all three** names the firmware may ask for. Every Pi 5
  Rev 1.1 and later is D0; set `pi5_soc=bcm2712-rpi-5-b` for a Rev 1.0 board.
  `test.sh` greps the staged DTBs for `pci1de4,1` and `bcm2712d0-pinctrl`.
  Two consequences that bite if forgotten:
  1. **Every `dtparam=` becomes a silent no-op.** dtparams are applied through
     the DTB's `__overrides__` node, which only downstream DTBs carry. This is
     why the cephfs layer no longer writes `dtparam=pciex1` — mainline's
     `bcm2712-rpi-5-b-base.dtsi` already sets `pcie1` (the M.2 slot) and `pcie2`
     (RP1) to `okay`, so the NVMe enumerates on its own.
  2. **Downstream `.dtbo` overlays cannot apply** (they patch labels a mainline
     DTB does not have), so `configure.sh` strips `dtoverlay=vc4-kms-v3d-pi5`.
     Mainline wires HDMI/v3d up in the DTB itself.
  Ceiling: the ESP is written at install time, so a `bootc upgrade` that changes
  kernels leaves a DTB from the old one. Fine while the DTB is stable; if it ever
  matters, move to GRUB's `devicetree` command in the BLS entry.
- **`dtparam=pciex1` is NOT used** (see above — it would be a no-op against the
  mainline DTB). PCIe comes up because mainline's DTB enables `pcie1`. Left at
  Gen 2 deliberately (Gen 3 is out of spec and the 1 GbE NIC is the real ceiling).
- **The network is the bottleneck, not the disk.** NVMe ≈450 MB/s (Gen 2) vs
  ~118 MB/s on the onboard 1 GbE. With 3× replication the primary OSD re-sends
  each write to two peers over that same NIC, so client writes cap around
  55–60 MB/s. Don't tune the storage path for throughput; add a NIC.
- **`/var/lib/ceph` is on the SD card**, and mon rocksdb is fsync-heavy. Fine for
  an OSD-only node; a colocated mon wants that directory moved to the NVMe.
- **The NVMe must stay raw** for `ceph orch daemon add osd`. Boot the OS from the
  SD card. If a future change makes `fedora-image` target the NVMe, the
  OSD story has to be rethought at the same time.
- The kernel CephFS client (`ceph.ko`, `libceph.ko`) autoloads on
  `mount -t ceph`; the flavor's `configure.sh` only *verifies* the modules exist
  in the image rather than preloading them.

## The `s3-versity` flavor

- **The server is versitygw, NOT MinIO, and swapping back would be a
  regression.** `minio/minio` is archived upstream (`"archived": true` via the
  GitHub API): last community release `RELEASE.2025-10-15…` (source only), last
  published image `RELEASE.2025-09-07T16-13-09Z`, no further security fixes, and
  the admin console was stripped from the community build in mid-2025.
  versitygw (`versity/versitygw`, Apache-2.0, v1.7.0) is actively released and
  publishes an arm64 manifest.
- **versitygw is a stateless gateway over a POSIX filesystem: a bucket is a
  directory, an object is a file at its key path.** That is the whole reason it
  was chosen over Garage and SeaweedFS, which are also good and also actively
  maintained but keep objects in opaque internal stores. Here the data survives
  the software: `cp -a` / `rsync -X` off the NVMe recovers everything, with no
  repair tool and no metadata DB. There is also nothing to bootstrap — no cluster
  layout, no node IDs, no admin token — so a reflashed image with the same NVMe
  serves the same buckets. Known gaps: **per-object ACLs are unimplemented and
  versioning is experimental**; bucket policies, multipart, presigned URLs,
  tagging and object lock work.
- **The NVMe holds three SIBLING directories (`data/`, `versions/`, `iam/`), and
  they cannot be nested.** `backend/posix/posix.go` `New()` does
  `os.Chdir(rootdir)` (so the root must already exist — hence the `ExecStartPre`
  setup script) and `validateSubDir()` explicitly rejects a versioning directory
  inside the root. Anything else placed under the root would be served over S3 as
  a bucket.
- **Global flags must come BEFORE the `posix` subcommand** in the Quadlet
  `Exec=` line, or versitygw exits with a usage error at every boot.
  `configure.sh` and `test.sh` both grep for the correct ordering. The container's
  entrypoint is `docker-entrypoint.sh`, which `exec`s the binary with whatever
  args it is given, so `Exec=` passes straight through.
- **Upstream's default port is `:7070`; we override it to 9000** because every
  S3 client and every piece of documentation assumes 9000. The credential
  env vars the binary reads are `ROOT_ACCESS_KEY` and `ROOT_SECRET_KEY`
  (`cmd/versitygw/main.go`).
- **XFS is chosen for extended attributes, not performance.** Object metadata
  (content type, ETag, tags, ACLs) lives in user xattrs on each file. The `attr`
  package is in `package.list` so the metadata can be inspected and, more
  importantly, so backups use `rsync -X`/`tar --xattrs` — a plain copy restores
  bytes but silently loses all object metadata.
- **The gateway is deployed as a podman Quadlet, not an RPM** — it is not
  packaged in Fedora and upstream ships a container.
  `overlay/usr/share/containers/systemd/s3.container` is the whole deployment;
  there is no wrapper script and no first-boot hook.
- **`systemctl enable` and the `.wants`-symlink trick DO NOT WORK on a Quadlet
  unit, and this is the single easiest thing to get wrong here.** `s3.service`
  is not a file: the `podman-system-generator` synthesises it into
  `/run/systemd/generator/` at every boot and applies the unit's `[Install]`
  section itself, exactly as `systemctl enable` would. A hand-written
  `/usr/lib/systemd/system/multi-user.target.wants/s3.service` symlink — the
  pattern the rest of this image uses to enable services offline — would dangle
  and silently do nothing. `[Install] WantedBy=multi-user.target` inside the
  `.container` file is the enablement, and because the generator re-runs each
  boot it is self-healing and needs nothing written to `/var`. A Quadlet with no
  `[Install]` never starts and gives no error; `configure.sh` and `test.sh` both
  check for it.
- **Quadlet search-path precedence is `/run` > `/etc/containers/systemd` >
  `/usr/share/containers/systemd`.** The image ships the vendor (lowest) copy, so
  an operator can override the whole unit by dropping a same-named file in
  `/etc`. `[Unit]`, `[Service]` and `[Install]` sections in a `.container` file
  pass straight through to the generated unit, which is how `ExecStartPre=` and
  the mount dependency get in.
- **`container-selinux` is in the BASE package list** (weak deps are off
  image-wide) — without it podman cannot label anything and the container will
  not start. It is shared with the cephfs flavor, which needs it for the same
  reason.
- **`x-systemd.makefs` is NOT usable here even though it is the obvious answer.**
  There is no static `systemd-makefs@.service` template — `systemd-fstab-generator`
  *synthesises* that unit (`generator_hook_up_mkfs()` in `src/shared/generator.c`),
  so the option only works through `/etc/fstab`. On a bootc host `/etc/fstab` is
  bootc's file (it writes the `/boot` entries at install time) and `/etc` is
  3-way merged on upgrade, so an image-owned mount does not belong there. We call
  the binary directly instead: `/usr/lib/systemd/systemd-makefs xfs /dev/nvme0n1`,
  which is exactly the `ExecStart=` the generator would have written.
- **Two guards protect the NVMe, and both are load-bearing.** `systemd-makefs`
  itself probes with libblkid and returns 0 without formatting if it finds a
  filesystem (`makefs.c`: *"is not empty (contains file system of type ...),
  exiting"*) — that is what makes the unit safe to run on every boot. But it
  probes for **filesystems, not partition tables**, so a disk carrying an OS
  looks blank to it and would be wiped. Hence the `ExecCondition=` that refuses
  any device with a `PTTYPE`. Never remove either one.
- **`var-lib-s3.mount` is deliberately not enabled.** Only `s3.service`'s
  `Requires=` pulls it in, which reproduces fstab's `nofail` semantics: a Pi with
  no NVMe boots fine and only S3 fails. The `Requires=`/`After=` pair also stops
  the gateway starting before the mount and writing objects into the empty mount
  point on the SD card. The unit name is the escaped mount path — rename the path
  and you must rename the file (`systemd-escape -p --suffix=mount`).
- **The data volume uses lowercase `:z`, not `:Z`.** `:Z` adds a per-container
  MCS category that changes on every start, which would force podman to
  recursively relabel the entire object store each time the service restarts. `:z`
  gives the stable `container_file_t:s0` label. Nothing else shares the volume.
- **No credentials in the image.** `/usr/libexec/s3-setup` creates the three
  directories and mints a random secret key into `/etc/s3/root.env` on first
  start, then never touches it again. It is a script rather than an inline
  `bash -c` because systemd expands `%` and `$` in `Exec=` lines before the shell
  sees them, which makes `printf` formats and `$(...)` a quoting minefield. It
  also refuses to run if `/var/lib/s3` is not a mount point, so a missing NVMe
  cannot end up filling the boot media. `test.sh` fails the build if `root.env`
  is ever found inside an image.
- **Single drive = no redundancy of any kind.** There is no erasure coding and no
  replication; a dead NVMe is dead data.
- **No TLS.** The gateway serves plain HTTP; it is a LAN appliance. Put a reverse
  proxy in front before exposing it.

## The `s3-garage` flavor

Same shape as `s3-versity` — a podman Quadlet plus a `systemd-makefs` NVMe
volume — so everything in that section about Quadlet enablement, the two format
guards, the unenabled mount unit and `:z` vs `:Z` applies here verbatim and is
not repeated. What follows is only what differs.

- **The server is Garage** (`garagehq.deuxfleurs.fr`, AGPLv3, actively
  developed). Canonical repo is **`git.deuxfleurs.fr/Deuxfleurs/garage`** — the
  GitHub repo is a MIRROR with issues disabled and `/releases` returning 404, so
  do not send anyone there for release notes or bug reports.
- **Two version floors, both hard.** `--single-node` needs **v2.3.0**, and
  **v2.2.0** fixed a SIGILL crash on Raspberry Pi and older ARM boards — anything
  older simply will not run on this hardware. `test.sh` parses the tag out of
  `Image=` and fails the build below v2.3. The image is
  `docker.io/dxflrs/garage:v2.3.0`, a manifest list with a real `linux/arm64`
  entry (~27 MB).
- **The image is `FROM scratch` with `CMD ["/garage","server"]` and NO
  ENTRYPOINT.** Arguments therefore REPLACE the command instead of being appended
  to it, so the Quadlet `Exec=` must spell out the binary path:
  `Exec=/garage server --single-node --default-bucket`. Drop the `/garage` and
  the container runs nothing. `configure.sh` and `test.sh` both grep for it.
- **`--single-node` replaces the entire old bootstrap.** Before v2.3.0 a fresh
  node came up with `NO ROLE ASSIGNED` and needed `garage layout assign -z … -c …
  <node-id>` then `garage layout apply --version N` by hand. The flag creates and
  applies the layout itself; `--default-bucket` additionally creates the initial
  access key and bucket from `GARAGE_DEFAULT_ACCESS_KEY` /
  `GARAGE_DEFAULT_SECRET_KEY` / `GARAGE_DEFAULT_BUCKET`. **UNVERIFIED: upstream
  does not document whether those env vars are re-read on every start or whether
  re-running against an already-bootstrapped node is idempotent.** The unit has
  `Restart=always`, so if a restart ever produces duplicate-key errors in the
  journal, that is the thing to look at first.
- **`db_engine = "sqlite"` is a deliberate override of Garage's LMDB default and
  must not be "corrected".** Upstream: LMDB "is prone to database corruption after
  an unclean shutdown (e.g. a process kill or a power outage)", and the documented
  mitigation is snapshots *or* switching to sqlite. On a normal cluster you would
  rebuild metadata from a peer; at `replication_factor = 1` there is no peer, and
  a corrupt metadata DB means every object is unreachable even though the blocks
  are intact. `metadata_fsync`/`data_fsync` are on for the same reason (both
  default to false) and `metadata_auto_snapshot_interval = "6h"` gives a clean
  restore point. All of it costs write throughput on purpose. `test.sh` fails the
  image if `db_engine` is not sqlite.
- **`replication_factor = 1` is the only valid value for one node** and upstream
  labels it "test deployments only" — that is a durability statement, not a
  stability one. Unlike single-node Ceph (actively discouraged), single-node
  Garage is a documented, first-class supported mode.
- **Object data is NOT recoverable without Garage.** Objects are split into
  `block_size` (1 MiB) chunks, zstd-compressed, deduplicated, and written as
  content-addressed blocks hashed into 1024 fixed slices; the S3-key-to-block
  mapping lives only in the metadata DB. There is no documented offline export
  tool. This is the one real regression against `s3-versity`, where a bucket is a
  directory and `cp -a` recovers everything — it is the trade-off to state
  whenever someone asks which flavor to use.
- **XFS is upstream's own recommendation here**, not just ours: "We recommend
  using XFS for the data partition... EXT4 is not recommended as it has more
  strict limitations on the number of inodes". Metadata and data sharing one
  drive is explicitly blessed for single-drive nodes. Garage needs no xattrs, so
  the `attr` package is absent from this flavor's `package.list`.
- **Metadata directories are architecture-specific** — an arm64 LMDB/SQLite meta
  dir cannot be opened on x86. And never copy a running node's metadata dir with
  `cp`; `garage meta snapshot` is the only consistent backup.
- **No secrets in `/etc/garage.toml`.** `rpc_secret` (required even for a single
  node — there is no way to disable it), the initial access key and the secret key
  are generated on the device by `/usr/libexec/garage-setup` into `/etc/garage/env`
  and injected via `EnvironmentFile=`. `test.sh` fails the image if either
  `/etc/garage/env` exists or `garage.toml` sets `rpc_secret`/`admin_token`/
  `metrics_token` inline. The RPC secret must be exactly 32 bytes of hex; the
  setup script asserts the length.
- **`configure.sh` cross-checks that `garage.toml` and `garage-setup` agree on
  `/var/lib/garage/{meta,data}`.** Garage exits at startup if either directory is
  missing, and it creates neither itself, so a path typo is a boot-time-only
  failure otherwise.
- **Published on 9000, not Garage's default 3900**, so all S3 flavors in this repo
  answer on the same port. RPC (3901) is deliberately not published — it is
  node-to-node and there is one node. `[s3_web]` (3902) and `[admin]` (3903) are
  omitted from the config entirely.
- **`/usr/bin/garage` is a four-line `podman exec garage /garage "$@"` wrapper.**
  The CLI and the server are the same binary and it only exists inside the
  container image; the wrapper also guarantees the CLI version always matches the
  server, which upstream requires. `ContainerName=garage` in the Quadlet is what
  makes the wrapper's container name predictable — Quadlet would otherwise name
  it `systemd-garage`.
- **Upgrades:** v2.x point releases need no metadata migration ("no breaking
  changes"); a major bump needs `garage migrate` and only works between
  contiguous majors. Bump the tag in `garage.container` and rebuild.

## Conventions

- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, tab indentation, colored
  `info`/`warn`/`die` helpers as in the existing scripts.
- Mark deliberate simplifications/known ceilings with a `# ponytail:` comment.
- Python tooling uses **uv**, never pip.
- Do NOT `git commit` — leave committing to the user.
