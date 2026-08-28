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
image/                        # the BASE layer
├── Containerfile         # FROM fedora-bootc + ONE build RUN
├── package.list          # packages to layer (deliberately short)
├── authorized_keys       # OPTIONAL, untracked: SSH keys for `fedora`
├── overlay/              # rootfs overlay, cp -a'd onto /
└── scripts/configure.sh  # Pi firmware relocation, user, services, kargs
flavors/cephfs/               # FROM the base: Ceph storage node (NVMe = OSD)
├── Containerfile         # FROM localhost/fedora-rpi5:latest
├── package.list          # cephadm, ceph-common, ceph-fuse, lvm2, chrony, nvme-cli
├── overlay/              # /etc/sysctl.d/90-ceph.conf
└── scripts/configure.sh  # chronyd + lvm2-monitor, /etc/ceph, module checks
```

## Build / test

```sh
sudo ./fedora-build                        # base image
sudo ./fedora-build cephfs                 # base + the cephfs layer
FEDORA_SKIP_BASE=1 sudo ./fedora-build cephfs   # reuse the base (fast iteration)
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
  card size. `image/overlay/.../bootc-generic-growpart.service.d/10-grow-on-bare-metal.conf`
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
- **SSH is ENABLED** — this is a headless device (the opposite of the old desktop
  tree, which removed `openssh-server`). If `image/authorized_keys` exists it is
  installed for the `fedora` user and password authentication + root login are
  disabled via `/etc/ssh/sshd_config.d/10-no-password.conf`; otherwise the build
  warns and password login (`fedora`/`fedora`) stays on.
- **The `fedora` user is created at BUILD TIME** (`useradd`/`chpasswd` in
  `configure.sh`), not by an installer — it then works under any install path.
  `test.sh` asserts it exists, is in `wheel`, and has a non-locked hash.
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
  requirement set. Don't "helpfully" add the daemon packages.
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
- **`dtparam=pciex1` is appended to the staged `config.txt`** by this layer's
  `configure.sh`. The Pi 5 does not probe its external PCIe port otherwise, and
  the failure mode is an NVMe that never shows up in `lsblk` — a Ceph node with
  no OSD. Left at Gen 2 deliberately (Gen 3 is out of spec and the 1 GbE NIC is
  the real ceiling).
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

## Conventions

- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, tab indentation, colored
  `info`/`warn`/`die` helpers as in the existing scripts.
- Mark deliberate simplifications/known ceilings with a `# ponytail:` comment.
- Python tooling uses **uv**, never pip.
- Do NOT `git commit` — leave committing to the user.
