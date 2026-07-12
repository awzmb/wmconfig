# Fedora

Scripts to build a custom **Fedora** image (a `bootc` / image-mode Fedora) as
a custom OS image and turn it into a **bootable USB installer** for bare-metal
machines.

The build is two layers: a shared **base** image (all the DE-agnostic tooling)
and a thin **flavor** layer on top that adds a desktop. Each layer is driven by
its own **Containerfile** with declarative inputs (package lists, a rootfs
overlay, setup scripts) next to it. `fedora-build` builds the base then the
selected flavor with `podman`; `fedora-usb` converts the result into an
installer with
[`bootc-image-builder`](https://github.com/osbuild/bootc-image-builder).

## Flavors

| Flavor       | Desktop                                   | Display manager |
| ------------ | ----------------------------------------- | --------------- |
| `gnome-sway` | GNOME + **Sway** (default) + Hyprland     | GDM             |
| `gnome`      | plain GNOME                               | GDM             |
| `kde`        | KDE Plasma (Wayland)                      | SDDM            |

All flavors share the same full base toolset (dev, gaming, virt, CLI, Tailscale,
Plymouth, …) — only the desktop environment differs.

## Contents

```text
fedora/
├── fedora-build              # build the base + a desktop flavor
├── fedora-usb                # build an installer ISO/raw image + flash to USB
└── flavors/
    ├── base/                 # shared DE-agnostic foundation -> localhost/fedora-base
    │   ├── Containerfile          # FROM rawhide; drives lists/scripts
    │   ├── package.list           # base dnf packages (system/dev/gaming/virt/CLI)
    │   ├── package-remove.list    # packages to remove
    │   ├── flatpak.list           # flatpaks installed on first boot
    │   ├── overlay/               # rootfs overlay (/etc, /usr config, services, helpers)
    │   ├── scripts/
    │   │   ├── setup-repos.sh      # RPM Fusion + Tailscale
    │   │   └── configure.sh        # services, timezone, locale, dconf, plymouth, initramfs
    │   └── bib/config.toml         # bootc-image-builder config (user, kickstart) — shared
    ├── gnome-sway/           # FROM base: GNOME + Sway + Hyprland
    │   ├── Containerfile
    │   ├── package.list
    │   ├── overlay/               # seatd, wlroots portals, suspend hook
    │   └── scripts/configure.sh   # GDM + Sway default session
    ├── gnome/                # FROM base: plain GNOME
    └── kde/                  # FROM base: KDE Plasma + SDDM
```

## Prerequisites

- A Fedora (or any) host with `podman` and `bootc-image-builder` access.
- Root privileges for `fedora-usb` (it runs a `--privileged` container and
  writes to a block device).

## Quick start

```sh
# 1. Build the OS image (base + flavor -> localhost/fedora-gnome-sway:latest)
sudo ./fedora-build gnome-sway

# 2. Build a bootable installer ISO and write it to a USB stick
sudo ./fedora-usb --device /dev/sdX gnome-sway
```

`lsblk` first to find the correct `/dev/sdX` — flashing is destructive.

## Building the image

```sh
sudo ./fedora-build [flavor]         # default flavor: gnome-sway
```

`fedora-build` always builds the shared base (`localhost/fedora-base:latest`)
first, then layers the flavor `FROM` it. Iterating on a flavor? Reuse an existing
base with `FEDORA_SKIP_BASE=1` to skip the slow base rebuild.

Useful environment overrides:

| Variable            | Effect                                                          |
| ------------------- | -------------------------------------------------------------- |
| `FEDORA_BASE`       | Override the base's `FROM` (rawhide) — passed as `--build-arg BASE` |
| `FEDORA_TAG`        | Override the built flavor image tag                            |
| `FEDORA_BASE_TAG`   | Override the base image tag (default `localhost/fedora-base:latest`) |
| `FEDORA_SKIP_BASE`  | Set to `1` to reuse an existing base instead of rebuilding it  |
| `PODMAN`            | Use a specific podman/buildah binary                           |

The package install step uses `--skip-unavailable --skip-broken`, so packages
without a Fedora equivalent for your release are skipped with a warning rather
than failing the whole build.

> **Base image:** the base Containerfile's `FROM` is `quay.io/fedora/fedora-bootc:rawhide`.

## Creating the bootable USB

```sh
sudo ./fedora-usb [options] [flavor]
```

| Option            | Default                                            | Notes                                  |
| ----------------- | -------------------------------------------------- | -------------------------------------- |
| `--type`          | `bootc-installer`                                  | also `anaconda-iso`, `raw`, `qcow2`    |
| `--rootfs`        | `xfs`                                              | root filesystem: `xfs`, `ext4`, `btrfs` |
| `--image`         | `localhost/fedora-<flavor>:latest`                 | image built by `fedora-build`     |
| `--config`        | `flavors/base/bib/config.toml`                     | bootc-image-builder config (shared)    |
| `--output`        | `./target`                                         | where artifacts are written           |
| `--device`        | (none)                                             | USB block device to flash, e.g. `/dev/sdb` |
| `--keep-installer`| off                                                | keep the generated Anaconda installer image |
| `--yes`           | off                                                | skip the flash confirmation prompt     |

`bootc-installer` produces an installer ISO — the recommended way to install
Fedora on bare metal. It works with **any** bootc image regardless of its
`/etc/os-release`. Now that the base is a standard Fedora image (os-release `ID`
`fedora`), bib's legacy `anaconda-iso` path works too, but `bootc-installer`
stays the robust, base-agnostic default.

For `bootc-installer`, bib needs the positional container to ship Anaconda and a
`--installer-payload-ref` for the OS image to install. `fedora-usb` builds
that Anaconda installer image automatically (layering the installer packages on
top of the clean image and passing the clean image as the payload), so the
**installed** OS stays free of installer-only packages. Without `--device`, the
artifact is left in `./target` and the exact `dd` command is printed.

The default installer user is `awzm` / password `fedora` — **change this**
in `flavors/base/bib/config.toml` (generate a hash with `mkpasswd -m sha512` or
`openssl passwd -6`, or switch to an SSH `key`).

## How the awzmlinux config was ported

The base + `gnome-sway` flavor port `../arkane/arkdep-build.d/awzmlinux` to
Fedora as closely as practical:

- **Packages** — the shared list is split: `flavors/base/package.list` holds all
  the DE-agnostic packages (Fedora/dnf names) and each flavor's `package.list`
  adds its desktop. RPM Fusion packages are annotated; Arch/arkdep-only packages
  (`arkdep`, `archiso`, `pacman-contrib`, `libnss-extrausers`, …) are dropped.
- **Overlays** — the `/etc` and `/usr` configs (keyd, sysctl, udev rules for
  OpenRGB/controllers/Wooting/DFU, GNOME dconf, …) live in the base overlay;
  the Sway/Hyprland-specific bits (seatd, wlroots portals, `suspend-hyprland`)
  live in the `gnome-sway` overlay.
- **Sway is the default window manager** in the `gnome-sway` flavor. GDM is the
  login manager and its `scripts/configure.sh` presets the installer user's
  default session to Sway via AccountsService (`gnome-shell` stays installed only
  because the GDM greeter uses it). Change `FEDORA_DEFAULT_USER` /
  `FEDORA_DEFAULT_SESSION` (e.g. to `hyprland`) to override; keep
  `FEDORA_DEFAULT_USER` in sync with the user in `flavors/base/bib/config.toml`.
- **AUR / Chaotic-AUR** → **RPM Fusion** (`scripts/setup-repos.sh`).
- **Rust CLI tools** are preferred where a Fedora package exists (`ripgrep`, `sd`,
  `du-dust`, `bottom`, `zoxide`, `zellij`, `eza`, `bat`, `fd-find`, …).
- **Flatpaks** are installed by a first-boot service (flatpak needs a writable
  `/var`, which only exists on the deployed system).

### Intentional differences from arkdep

- No `abin`/`pacman`/`arkane-readonly` wrappers: immutability and transient
  package layering are handled natively by **bootc** (`bootc usroverlay`,
  `bootc switch`, atomic image updates) instead of arkdep's Btrfs read-only
  subvolumes.
- No `libnss-extrausers`/custom `nsswitch.conf`: bootc uses standard user
  management.
- `update.sh` (arkdep boot-entry migration) has no analogue: Fedora updates
  are atomic image pulls via `bootc upgrade`.

## After installation

On the installed system, the OS is a read-only bootc image. You do **not** use
`dnf install` to permanently add software the way you would on a traditional
Fedora install — instead you update or replace the whole image atomically, and
the previous deployment always stays available for rollback (`sudo bootc rollback`).

### Updating the OS

```sh
sudo bootc upgrade        # pull + stage the newest published image, reboot to apply
sudo bootc status         # show booted / staged deployments
```

**Automatic updates:** the base image enables `bootc-fetch-apply-updates.timer`,
so the system periodically pulls and atomically applies newer published images on
the next boot. Disable with
`sudo systemctl disable --now bootc-fetch-apply-updates.timer`.

> **Important — the `localhost/` payload gotcha.** The installer records the image
> reference it was given as the system's update source. If you built the USB from a
> purely local image (`localhost/fedora-gnome-sway:latest`), the installed machine
> has no way to pull updates and `bootc upgrade` / the auto-update timer will fail.
> Push the image to a registry **once** and point the machine at it:
>
> ```sh
> # on the build host
> podman push localhost/fedora-gnome-sway:latest <registry>/<repo>:latest
> # on the installed machine, one time
> sudo bootc switch <registry>/<repo>:latest
> ```
>
> From then on `bootc upgrade` and the timer track that registry tag.

### Adding / removing packages (the Silverblue equivalent)

bootc has no `rpm-ostree install`. The native way to keep extra packages across
updates is to **build a small derived image and switch to it**. Fedora ships
a helper, `fedora-layer`, that automates this:

```sh
sudo fedora-layer add htop neovim   # layer packages, stage for next boot
sudo fedora-layer remove htop       # drop a package, rebuild
sudo fedora-layer list              # show layered packages
sudo fedora-layer update            # re-pull upstream + re-apply your layers
sudo fedora-layer reset             # drop all layers, back to the pristine image
sudo fedora-layer status            # bootc status
reboot                                   # activate any staged change
```

Under the hood it writes a one-line `Containerfile` (`FROM <upstream> ` +
`RUN dnf install …`), `podman build`s it to `localhost/fedora-layered:latest`,
and runs `bootc switch --transport containers-storage …`. State lives in
`/etc/fedora/layer/` (`base` = upstream ref, `packages` = your list). The
upstream ref is auto-detected from `bootc status` on first use, or set it
explicitly with `sudo fedora-layer base <registry>/<repo>:tag`.

> Because a layered machine boots a **local** image, the automatic update timer
> can no longer fetch OS updates for it. Run `sudo fedora-layer update` to
> re-pull the upstream base and rebuild your layers on top — that is how a layered
> system receives OS updates.

For a quick, **transient** change (gone on next boot), use
`sudo bootc usroverlay` then `dnf install …`.

### Silverblue → bootc cheat sheet

| Silverblue (`rpm-ostree`)        | Fedora (`bootc`)                                  |
| -------------------------------- | ----------------------------------------------------- |
| `rpm-ostree upgrade`             | `bootc upgrade`                                        |
| `rpm-ostree rebase <ref>`        | `bootc switch <ref>`                                   |
| `rpm-ostree install <pkg>`       | `fedora-layer add <pkg>` (build + `bootc switch`) |
| `rpm-ostree uninstall <pkg>`     | `fedora-layer remove <pkg>`                       |
| `rpm-ostree status`              | `bootc status`                                         |
| `rpm-ostree rollback`            | `bootc rollback`                                       |
| `rpm-ostree install` (one-shot)  | `bootc usroverlay` + `dnf install` (transient)         |

