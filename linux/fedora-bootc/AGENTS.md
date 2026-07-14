# AGENTS.md

Guidance for AI agents working in this repo.

## What this is

Scripts that build a custom **Fedora** — a `bootc` / image-mode Fedora desktop
image — turn it into a bootable USB installer, and update an installed system
in place. The build is **two layers**: a shared DE-agnostic **base** image and a
thin **flavor** layer that adds a desktop. Each layer is driven by one
**Containerfile** with declarative config next to it.

## Layout

```
fedora-build                       # build base + selected flavor (podman build)
fedora-usb                         # build LIVE installer ISO (tacklebox) + flash to USB
fedora-update                      # day-2: rebuild locally + `bootc switch` for next boot
flavors/
├── base/                          # shared foundation -> localhost/fedora-base
│   ├── Containerfile                   # FROM rawhide + all base build steps
│   ├── package.list                    # DE-agnostic dnf packages
│   ├── package-remove.list             # packages removed in configure.sh
│   ├── flatpak.list                    # flatpaks installed on first boot
│   ├── overlay/                        # base rootfs overlay, cp -a'd onto /
│   ├── scripts/setup-repos.sh          # RPM Fusion + Tailscale (before packages)
│   ├── scripts/configure.sh            # services, locale, plymouth, initramfs, login user
│   ├── live/install.sh                 # in-live installer: LUKS + bootc install to-filesystem
│   └── live/customize-live.sh          # tacklebox live_customize: TTY autolaunch of install.sh
├── gnome-sway/                    # FROM base: GNOME + Sway (default) + Hyprland
├── gnome/                         # FROM base: plain GNOME
└── kde/                           # FROM base: KDE Plasma + SDDM
    ├── Containerfile                   # FROM base + desktop packages
    ├── package.list                    # desktop packages
    ├── scripts/configure.sh            # display manager + session enablement
    └── overlay/                        # desktop overlay (optional)
```

Flavors: `gnome-sway` (default), `gnome`, `kde`. All share the full base
toolset — only the desktop environment + display manager + session differ.
`fedora-build` builds the base first, then the flavor `FROM` it.

## Build / test

```sh
./fedora-build                       # build base + gnome-sway (default flavor)
./fedora-build kde                   # build base + kde
FEDORA_SKIP_BASE=1 ./fedora-build kde  # reuse an existing base (faster iteration)
sudo ./fedora-usb kde                # build LIVE installer ISO for a flavor into ./target
sudo ./fedora-usb --device /dev/sdX  # ...and flash it (DESTRUCTIVE)
sudo ./fedora-update                 # day-2: rebuild locally + stage for next boot
sudo ./fedora-update --apply kde     # ...and reboot into the kde flavor now
bash -n <script>                          # syntax-check a changed shell script
```

Overrides: `FEDORA_BASE` (base FROM, via `--build-arg BASE`), `FEDORA_TAG`,
`FEDORA_BASE_TAG`, `FEDORA_SKIP_BASE`, `PODMAN`. There is no separate test suite;
a real build needs `podman`, network, and pulls a multi-GB rawhide base, so it
can't run in a lightweight sandbox — validate shell changes with `bash -n` and
reason about the Containerfiles.

## Key facts / gotchas

- **Two-layer build.** `flavors/base` (FROM rawhide) is the shared foundation;
  each flavor (`gnome-sway`/`gnome`/`kde`) is `FROM localhost/fedora-base` and only
  adds a desktop. Keep DE-agnostic changes in `base`, desktop-specific ones in the
  flavor. The base ships the Fedora/RPM Fusion/Tailscale repos, so flavor layers
  don't re-run `setup-repos.sh`.
- **Base is `quay.io/fedora/fedora-bootc:rawhide`** — a standard Fedora image that
  already ships the Fedora repos + GPG keys. `base/scripts/setup-repos.sh` only
  adds RPM Fusion + the Tailscale repo. Do NOT reintroduce the old distroless-base
  repo-overlay/priority/release-detection machinery.
- **Package install uses `--skip-unavailable --skip-broken`** — a missing package
  is dropped with a warning, not a build failure. Each `configure.sh` re-checks a
  few critical binaries and warns loudly (base: NetworkManager/python/fc-cache;
  flavors: their DM + shell, e.g. gdm/sway, gdm/gnome-shell, sddm/plasmashell).
- **RPM Fusion may lag a fresh rawhide bump**; `setup-repos.sh` continues without
  it if the release RPM 404s.
- **Wi-Fi needs vendor firmware + `kernel-modules-extra` explicitly.** Fedora's
  `linux-firmware` no longer bundles per-vendor blobs (split like the GPU/Intel
  firmware above) — non-Intel adapters need `realtek-firmware`,
  `atheros-firmware`, `brcmfmac-firmware`, `mediatek-firmware`, `mt7xxx-firmware`,
  `libertas-firmware` explicitly (`flavors/base/package.list`). Some drivers
  (rtw88/rtw89, mt76, ath9k_htc, …) also ship only in the `kernel-modules-extra`
  split, not the base kernel package the bootc base pulls in — without it the
  adapter has no driver at all, not just no firmware.
- **Overlay is applied once per layer, after that layer's packages, before its
  `configure.sh`** so our files win over package-shipped ones and the
  dracut.conf.d/units are present when `configure.sh` runs.
- **Each Containerfile is ONE `RUN` over a bind-mounted context** (no `COPY`), so
  no build cruft (dnf cache, logs, the variant dir) is ever baked into a layer —
  deleting files in a *later* layer does NOT reclaim space, so setup+install+
  overlay+configure+cleanup must share one RUN. `dnf` installs pass
  `--setopt=install_weak_deps=False` to drop non-essential recommends (the big
  size lever); critical drivers/firmware/mesa/portals are listed explicitly so
  nothing needed is lost. Flip weak deps back on if a desktop feature goes missing.
- **podman does NOT hash the bind-mounted context**, so editing `scripts/`,
  `package.list` or `overlay/` would reuse the cached (stale) RUN layer and the
  rebuilt image would silently be old. `fedora-build` defends against this by
  passing `--build-arg CACHEBUST=<content-hash>` (via `ctx_hash`), which each
  Containerfile's RUN references (`: "cachebust ${CACHEBUST}"`). Keep both the
  `ARG CACHEBUST`/reference and the `ctx_hash` args when touching the build.
- **`fedora-usb` runs rootful** (`sudo`): it builds a LIVE installer ISO with
  tacklebox (`tuna-os/tacklebox`, run as the `ghcr.io/tuna-os/tacklebox` privileged
  container), which needs root's podman storage. tacklebox packs the flavor image
  into a squashfs live env (its own systemd-boot + `tbox-live` initramfs; the
  image's grub2 only matters for the INSTALLED system) and embeds the same image as
  an `offline_payloads` entry (packed into the ISO at `LiveOS/store.squashfs.img`)
  for offline install. IMPORTANT: tacklebox only AUTO-mounts that store for
  tacklebox-*prepared* images; a generic bootc image like ours ships neither the
  mount nor the containers/storage wiring, so `customize-live.sh` bakes a
  `storage.conf.d` drop-in (`additionalimagestores=[/var/lib/superiso-store]`) and
  `install.sh` loop-mounts `LiveOS/store.squashfs.img` there before installing —
  without both, the installer dies "no localhost/fedora-* image found". Root's
  storage is
  separate from a rootless `./fedora-build`; `fedora-usb` compares image IDs and
  re-syncs (save|load) when they differ, using a root-storage image directly when
  present. Building rootful too (`sudo ./fedora-build`) avoids the copy — recommend
  that. It generates the tacklebox `recipe.json` in a temp build dir next to copies
  of `flavors/base/live/{install.sh,customize-live.sh}` (live_customize paths are
  relative to the recipe). The old bib/Anaconda `anaconda-iso` path has been removed
  (see the install-encryption bullet).
- **`fedora-update` is the day-2 path** (in-place update of an installed system):
  it runs `fedora-build` ROOTFUL (must be root so the rebuilt image lands in the
  store bootc reads) then `bootc switch --transport containers-storage
  localhost/fedora-<flavor>:latest` to stage it for the next boot. `switch`
  re-reads the freshly built image each run, so it doubles as the re-deploy
  command; `--apply` reboots; `bootc rollback` reverts. bootc has no rootless
  mode — same root requirement as `fedora-usb`.
- **Plymouth runs in USERSPACE, not the initramfs**: the initramfs carries only
  `ostree crypt systemd-cryptsetup lvm dm` (declared in `base/overlay/etc/dracut.conf.d/fedora.conf`
  via `add_dracutmodules`); base `configure.sh` selects a Plymouth theme, writes
  `rhgb quiet` kargs (`/usr/lib/bootc/kargs.d`) and regenerates the initramfs.
  `bootc install` (run by `live/install.sh`) bakes these `kargs.d` snippets into the
  installed BLS entry, so no bootloader override is needed. crypt/systemd-cryptsetup/lvm/dm are needed to unlock the LUKS root;
  the generic initramfs unlocks LUKS via systemd-cryptsetup-generator from
  `rd.luks.uuid=`, so `systemd-cryptsetup` must be added explicitly (`crypt` only
  pulls it in hostonly mode) or first boot dies "systemd-cryptsetup@luks-…not found";
  the LUKS passphrase prompt is text-mode (no in-initramfs plymouth) and the
  graphical splash appears in userspace after unlock.
- **The LUKS root's disk-not-appearing hang is because the `nvme` driver doesn't
  autoload — not a karg or the unit-name escaping (that's a separate second bug,
  below).** This is a
  GENERIC (`--no-hostonly`) initramfs, which relies on udev coldplug to autoload
  storage drivers from PCI modaliases. On this rawhide that autoload does NOT fire for
  `nvme`, so the root disk never appears: `systemd-cryptsetup` blocks on its
  `BindsTo=dev-disk-by-uuid-<uuid>.device` dependency, times out ("Timed out waiting
  for device …"), and NO passphrase is ever prompted — boot hangs. Proven on-machine:
  at an `rd.break` shell `/proc/partitions` was empty and `/dev/nvme*` absent; a manual
  `modprobe nvme` made the disk appear and `systemctl start cryptsetup.target` then
  prompted and unlocked via the STOCK generator path (the generator had correctly
  wired `cryptsetup.target.requires/systemd-cryptsetup@luks\x2d<uuid>.service`, single
  backslashes). Fix: `force_drivers+=" nvme "` in
  `base/overlay/etc/dracut.conf.d/fedora.conf` plus `--force-drivers nvme` on the
  `configure.sh` dracut cmdline, which modprobes nvme unconditionally at initramfs
  start. `test.sh` asserts the `nvme` driver is in the initramfs.
- **A SECOND, independent LUKS bug: dracut's `70crypt` mis-escapes the unlock unit
  name and it IS fatal on normal boot.** Once the disk appears, dracut's
  `parse-crypt.sh` (systemd mode) writes a udev rule that runs
  `systemctl start systemd-cryptsetup@<name>.service`, but it DOUBLES the backslash in
  the escaped instance (`luks\x2d…` -> `luks\\x2d…`) to survive a layer of udev
  unescaping. Rawhide udev no longer unescapes `RUN=` strings, so the doubled name
  reaches systemctl verbatim, matches no unit, and normal boot loops on
  `Failed to start systemd-cryptsetup@luks\\x2d….service` — the passphrase prompt never
  unlocks. (Manual unlock works because at an `rd.break` shell udev hasn't fired that
  rule; only the generator's single-escaped `cryptsetup.target.requires/…` unit runs.)
  Fix: `configure.sh` `sed`-patches `parse-crypt.sh` before the initramfs regen to drop
  the backslash-doubling (`str_replace "$luksname" '\' '\\'` lines), so the udev-rule
  path targets the SAME correctly-escaped unit the generator wires. `test.sh` asserts
  the initramfs `parse-crypt.sh` no longer doubles. Ceiling: revert once rawhide udev
  restores `RUN=` unescaping or dracut stops doubling. An earlier `luks-unlock-fix`
  dracut module was removed — it solved the wrong problem and never shipped into the
  booted initramfs anyway; the `sed` patch rides the proven fedora.conf/configure.sh
  channel instead.
  `rd.luks.options=x-initrd.attach` is set via `kargs.d/15-luks.toml` (a global LUKS
  option baked into the installed BLS entry by `bootc install`) and IS required: it
  makes the generator emit the unlock unit into the initrd and wire
  `cryptsetup.target`. The device itself is named post-install by `live/install.sh`
  appending `rd.luks.name=<uuid>=root` to the BLS options line. If this fleet ever
  boots SATA/virtio roots, add `ahci`/`sd_mod`/`virtio_blk` to `force_drivers` too.
- **Force-adding `ostree` to the initramfs is mandatory, not cosmetic.** Because we
  force-regenerate the initramfs, we MUST re-add the `ostree` dracut module or the
  regen silently drops it and the image can't mount its composefs/ostree root →
  unbootable. This is why `ostree` is in `add_dracutmodules` and `configure.sh`
  verifies (via `lsinitrd`) that `ostree` landed. Every bootc image project does
  the same `--add ostree` (see bootc-dev/bootc #1084). configure.sh also builds
  `--reproducible`, sets `DRACUT_NO_XATTR=1` (container overlayfs), `chmod 0600`s
  the image, and asserts NO `i915`/`xe`/`amdgpu` leaked in.
- **Keep `drm` and `plymouth` OUT of the initramfs (`omit_dracutmodules`).** The
  `plymouth` dracut module drags in `drm` + every GPU KMS driver, so i915 would
  probe in the initramfs where its GuC/HuC firmware (`intel-gpu-firmware`, only on
  the real root) is absent — GuC never loads, never retries after pivot, and the
  GPU can't do command submission: Plymouth's dumb scanout still paints (masking
  it) but the console and GDM/mutter black-screen and hang. Omitting drm/plymouth
  lets the kernel use EFI-GOP/`simpledrm` early and load the GPU driver after pivot
  with firmware present — matching stock Fedora and `TypicalAM/fedora-bootc`
  (`dracut --omit "drm ... plymouth"`). Do NOT re-add plymouth/drm or `add_drivers`
  GPU modules to the initramfs.
- **Display manager + default session are per-flavor** (gnome-sway/gnome → GDM,
  kde → SDDM); the base sets no DM. Enablement is static. All three flavors now
  default to `graphical.target` (GDM/SDDM autostart on boot); fall back to
  `sudo systemctl set-default multi-user.target` if the GPU/compositor misbehaves.
- **No SSH server** — this is a desktop device; `openssh-server` is removed
  (package-remove.list) and `sshd.service` is not enabled. openssh-clients stays.
- **Service enablement is static** (`.wants` symlinks written into `/usr`), because
  `systemctl enable` is unreliable in an offline image build. Keep that pattern.
- **Install-time disk encryption + install flow use the tacklebox live ISO +
  `flavors/base/live/install.sh`** (the fisherman recipe), NOT Anaconda. The
  installer partitions the target (ESP + **unencrypted ext4 `/boot`** + LUKS2 root),
  `cryptsetup luksFormat`/`luksOpen` the root itself, then runs `bootc install
  to-filesystem --source-imgref containers-storage:<image>` NATIVELY (not `podman
  run <image> bootc install`) into the OPEN `/dev/mapper` — so bootc never sees LUKS
  and writes plain `root=UUID=<fs>`. The native `--source-imgref` path (dakota
  "bootcDirect") reads layers straight from the offline store without materializing
  a container rootfs, avoiding the overlay-on-overlay blowup a `podman run` hits in
  the live env's overlayfs root. Unlock is wired POST-install by appending
  **`rd.luks.name=<LUKS-header-UUID>=root`** to the BLS `options` line (maps the
  container to `/dev/mapper/root` for systemd-gpt-auto-generator). The exact karg
  form is boot-critical: `rd.luks.uuid=` or a bare name hangs ~90s into an emergency
  shell (dakota #270). No `/etc/crypttab` needed; the initrd `crypt` module unlocks
  from the karg. `install.sh --self-test` checks the BLS-patch logic. The **login
  `fedora` user is created at BUILD TIME** in `flavors/base/scripts/configure.sh`
  (`useradd`/`chpasswd`), NOT by the installer — the old Anaconda kickstart password
  never produced a working console login on this ostree target ("Login incorrect");
  an account baked into the image's `/etc/passwd`+`/etc/shadow` works regardless of
  install path. `test.sh` asserts the `fedora` user exists, is in `wheel`, and has a
  non-locked password hash. The old `flavors/base/bib/` (Anaconda kickstart) has been
  removed; its LUKS passphrase == login password convention no longer applies.

## Conventions

- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, tab indentation, colored
  `info`/`die` helpers as in the existing scripts.
- Mark deliberate simplifications/known ceilings with a `# ponytail:` comment.
- Python tooling uses **uv**, never pip.
- Do NOT `git commit` — leave committing to the user.
