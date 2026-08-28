# fedora-rpi5

A **minimal Fedora bootc (image-mode) OS for a Raspberry Pi 5**, built as a
container image, written to an SD card / NVMe as a raw disk image, and updated
in place afterwards.

One image, one layer — plus optional thin flavor layers on top.

```
fedora-build      # build the container image (aarch64)
fedora-image      # build a raw disk image and flash it to SD/USB/NVMe
fedora-update     # day-2: rebuild on the Pi + stage for the next boot
test.sh           # inspect a built image before flashing
image/
├── Containerfile         # FROM fedora-bootc + the single build RUN
├── package.list          # packages to layer (keep it short)
├── authorized_keys       # OPTIONAL: SSH keys for the `fedora` user (not committed)
├── overlay/              # rootfs overlay, cp -a'd onto /
└── scripts/configure.sh  # Pi firmware, user, services, kargs
flavors/
└── cephfs/               # FROM the base: Ceph node with the NVMe as an OSD
    ├── Containerfile
    ├── package.list
    ├── overlay/          # /etc/sysctl.d/90-ceph.conf
    └── scripts/configure.sh
```

## Quick start

```sh
sudo ./fedora-build                          # localhost/fedora-rpi5:latest
sudo ./fedora-build cephfs                   # localhost/fedora-rpi5-cephfs:latest
sudo ./test.sh localhost/fedora-rpi5-cephfs:latest
sudo ./fedora-image cephfs --device /dev/mmcblk0    # write the SD card (DESTRUCTIVE)
```

Then boot the Pi. Login is `fedora` / `fedora` on the HDMI console, the serial
header (115200 8N1) or over SSH. **Change the password, or drop your public key
into `image/authorized_keys` before building** — that also disables SSH password
authentication automatically.

Build on the Pi (or any aarch64 box) if you can: on x86_64 the build is
cross-emulated through `qemu-user-static` and roughly 10x slower.

```sh
# x86_64 host: register the aarch64 binfmt handler once per boot
sudo podman run --privileged --rm docker.io/multiarch/qemu-user-static --reset -p yes
```

## How the Pi 5 boots this

The Pi 5 has **no UEFI firmware**. The boot chain is:

```
BCM2712 EEPROM → config.txt → rpi-u-boot.bin (U-Boot, provides EFI) → GRUB2-EFI → BLS entry → kernel
```

`bcm283x-firmware` + `uboot-images-armv8` install those files into `/boot/efi`,
which a bootc image may not own. So `image/scripts/configure.sh`:

1. copies them to `/usr/lib/bootc-rpi-firmware/` (U-Boot renamed `rpi-u-boot.bin`),
2. removes both packages and `/boot/efi`,
3. shims `/usr/bin/bootupctl` so that when `bootc install` calls
   `bootupctl backend install <dest>`, the firmware is copied onto the freshly
   created ESP first.

This is the standard workaround while [bootupd has no Raspberry Pi
support](https://github.com/coreos/bootupd/issues/766).

## The `cephfs` flavor

Turns the Pi into a Ceph node whose **NVMe becomes an OSD**. The image ships
`cephadm`, `ceph-common` (CLI + `mount.ceph`), `ceph-fuse`, LVM, chrony and NVMe
tooling — but **no Ceph daemon RPMs**: cephadm runs mon/mgr/osd/mds as podman
containers from `quay.io/ceph/ceph` (multi-arch, arm64 included), which is the
upstream-supported path and decouples the cluster version from Fedora's.

Nothing cluster-specific is baked in — an image cannot know your fsid, mons or
keys. After first boot:

```sh
# --- new cluster (first node) ---
sudo cephadm bootstrap --mon-ip <this-pi-ip>

# --- or join an existing one, from the cluster's admin host ---
ceph orch host add pi5 <this-pi-ip>

# --- hand the NVMe to Ceph (WIPES IT) ---
lsblk                                    # confirm the device, e.g. /dev/nvme0n1
sudo ceph orch daemon add osd pi5:/dev/nvme0n1

# --- create and mount a filesystem ---
sudo ceph fs volume create data
sudo mount -t ceph <mon-ip>:6789:/ /mnt/data \
     -o name=admin,secretfile=/etc/ceph/ceph.client.admin.keyring
```

`cephadm bootstrap` writes `ceph.conf` and the admin keyring into `/etc/ceph`,
which is preserved across `fedora-update`, so cluster identity survives an OS
update.

Notes:

* **The root filesystem must not live on the NVMe you give to Ceph.** Boot from
  the SD card and keep the NVMe raw.
* **`dtparam=pciex1` is appended to `config.txt`** by this layer — without it the
  Pi 5 often does not probe the PCIe port and the NVMe never appears.
* **`nvme.max_host_mem_size_mb=128` is set** (via `kargs.d`). DRAM-less NVMe
  drives — the Samsung 990 EVO among them — ask for 64 MiB of Host Memory Buffer,
  the Pi 5 caps HMB at 32 MiB, and on a request over the cap the kernel disables
  HMB *entirely* rather than shrinking it. The result is IO stalls and hard
  lockups under sustained writes. Check with
  `dmesg | grep -i 'host mem'` — you want "allocated 64 MiB host memory buffer",
  not "above limit".
* **The 1 GbE NIC is the bottleneck, not the disk.** The NVMe does ~450 MB/s
  (PCIe Gen 2); the onboard Ethernet does ~118 MB/s, and with 3× replication a
  primary OSD must send each write out twice, so expect **~55–60 MB/s of client
  writes** and ~110 MB/s of reads per node. Reach for a USB3 2.5 GbE adapter
  before you reach for `dtparam=pciex1_gen=3`.
* **Ceph's mon/mgr state lands on the SD card** (`/var/lib/ceph`), and it is
  fsync-heavy. On a node that also runs a mon, move it to the NVMe or expect slow
  ops and a worn-out card.
* **Time sync is mandatory** — the Pi 5 has no RTC and monitors reject clock
  skew, so `chronyd` is enabled by the flavor.
* `fs.aio-max-nr` and `kernel.pid_max` are raised in
  `/etc/sysctl.d/90-ceph.conf`; the defaults will make BlueStore OSDs fail.

## Day 2

```sh
sudo ./fedora-update            # rebuild on the Pi, stage for next boot
sudo ./fedora-update cephfs     # ...the cephfs image instead
sudo ./fedora-update --apply    # ...and reboot now
sudo bootc rollback && sudo systemctl reboot   # undo
```

`fedora-update` only updates the OS. The Pi firmware and U-Boot on the ESP are
written once at install time — re-flash the card to update those.

## Known limitations

* **The disk image is always 10 GiB.** `image-builder` hard-codes that default
  for bootc raw images (with a `containerSize × 2` floor) and exposes no
  `--size` flag. The file is sparse — `du` shows ~2.8 GiB — but `dd` writes all
  10 GiB, so flashing takes a while on a slow reader. `bmaptool copy` skips the
  holes if you have it. The root filesystem grows to fill the card on first
  boot, so the card size, not the image size, is what you end up with.

* **Mainline kernel support for the Pi 5 (BCM2712/RP1) is still incomplete.**
  HDMI, PCIe/NVMe and some peripherals may misbehave on the generic Fedora
  aarch64 kernel. The serial console is baked into the kernel args for exactly
  that reason. If you hit hardware gaps, try
  [pbrobinson/a64-kernel](https://copr.fedorainfracloud.org/coprs/pbrobinson/a64-kernel/).
* **No disk encryption.** A headless Pi has nobody to type a passphrase and no
  TPM to hold one.
* **Boot from SD or USB is the tested path**; NVMe boot depends on your EEPROM
  `BOOT_ORDER` and on PCIe working in the running kernel.

## Configuring

* **Packages** — `image/package.list`. The `fedora-bootc` base already ships
  systemd, dnf, bootc, coreutils, vim-minimal and openssh-clients; only add what
  it does not.
* **Files** — drop them in `image/overlay/`, mirroring the target paths.
* **Kernel args** — `/usr/lib/bootc/kargs.d/*.toml`, written by `configure.sh`.
* **Base image** — `FEDORA_BASE=quay.io/fedora/fedora-bootc:43 ./fedora-build`.
* **Tag** — `FEDORA_TAG=localhost/my-pi:latest`.

## Credits

The Pi firmware relocation + `bootupctl` shim pattern comes from
[ondrejbudai/fedora-bootc-raspi](https://github.com/ondrejbudai/fedora-bootc-raspi)
and [supakeen's write-up](https://supakeen.com/weblog/bootc-on-the-raspberry-pi/).
