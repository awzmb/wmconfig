# Hummingbird

Scripts to build **Fedora Hummingbird Linux** (a `bootc` / image-mode Fedora) as
a custom OS image and turn it into a **bootable USB installer** for bare-metal
machines.

The configuration layout intentionally mirrors
[`arkdep-build.d`](https://github.com/arkanelinux/arkdep) (the Arkane Linux
declarative image config used in `../arkane`). Where arkdep `pacstrap`s a root and
`chroot`s into it, Hummingbird is image-mode Fedora, so the same declarative
inputs (package lists, overlays, extension hooks) are instead rendered into a
**Containerfile** and built with `podman`, then converted to an installer with
[`bootc-image-builder`](https://github.com/osbuild/bootc-image-builder).

## Contents

```text
hummingbird/
├── hummingbird-build              # build the bootc OS image from a variant
├── hummingbird-usb                # build an installer ISO/raw image + flash to USB
└── hummingbird-build.d/
    └── awzm-hummingbird/          # a variant (ports the Arch awzmlinux config)
        ├── type                   # "fedora"
        ├── name.sh                # image name (arkdep name.sh)
        ├── base.list              # base image / FROM (arkdep bootstrap.list)
        ├── package.list           # dnf packages to layer
        ├── package-remove.list    # packages to remove
        ├── copr.list              # COPR repos (Fedora analogue of AUR/Chaotic-AUR)
        ├── flatpak.list           # flatpaks installed on first boot
        ├── python-tools.list      # uv tools installed on first login
        ├── overlay/
        │   ├── post_bootstrap/    # /etc, /usr config applied before packages
        │   └── post_install/      # services + helper scripts applied after packages
        ├── extensions/
        │   ├── pre_build.sh        # repo setup (RPM Fusion + COPR)
        │   ├── post_bootstrap.sh   # early hook
        │   ├── post_install.sh     # services, timezone, removals, dconf, sway tweak
        │   └── post_build.sh       # after-build hook (push/sign)
        └── bib/
            └── config.toml         # bootc-image-builder config (user, kickstart)
```

## Prerequisites

- A Fedora (or any) host with `podman` and `bootc-image-builder` access.
- Root privileges for `hummingbird-usb` (it runs a `--privileged` container and
  writes to a block device).

## Quick start

```sh
# 1. Build the OS image (creates localhost/awzm-hummingbird:latest)
sudo ./hummingbird-build awzm-hummingbird

# 2. Build a bootable installer ISO and write it to a USB stick
sudo ./hummingbird-usb --device /dev/sdX awzm-hummingbird
```

`lsblk` first to find the correct `/dev/sdX` — flashing is destructive.

## Building the image

```sh
sudo ./hummingbird-build [variant]        # default variant: awzm-hummingbird
```

Useful environment overrides:

| Variable           | Effect                                                       |
| ------------------ | ------------------------------------------------------------ |
| `HUMMINGBIRD_BASE` | Override the base image (FROM) instead of reading base.list  |
| `HUMMINGBIRD_TAG`  | Override the built image tag                                 |
| `PODMAN`           | Use a specific podman/buildah binary                         |
| `KEEP_CONTEXT=1`   | Keep the temporary build context (generated Containerfile)   |

The package install step uses `--skip-unavailable --skip-broken`, so packages
without a Fedora equivalent for your release are skipped with a warning rather
than failing the whole build.

> **Base image:** `base.list` defaults to `quay.io/fedora/fedora-bootc:42` — the
> official, public Fedora image-mode base on quay.io. "Fedora Hummingbird" is a
> project layered on top of standard Fedora bootc, not a separate registry image.
> Change the tag to `43`, `rawhide`, or `latest` as needed.

## Creating the bootable USB

```sh
sudo ./hummingbird-usb [options] [variant]
```

| Option          | Default                                            | Notes                                  |
| --------------- | -------------------------------------------------- | -------------------------------------- |
| `--type`        | `anaconda-iso`                                     | also `raw`, `qcow2`, `iso`             |
| `--image`       | `localhost/<variant>:latest`                       | image built by `hummingbird-build`     |
| `--config`      | `hummingbird-build.d/<variant>/bib/config.toml`    | bootc-image-builder config             |
| `--output`      | `./target`                                         | where artifacts are written           |
| `--device`      | (none)                                             | USB block device to flash, e.g. `/dev/sdb` |
| `--yes`         | off                                                | skip the flash confirmation prompt     |

`anaconda-iso` produces a graphical installer ISO — the recommended way to
install Hummingbird on bare metal. Without `--device`, the artifact is left in
`./target` and the exact `dd` command is printed.

The default installer user is `awzm` / password `hummingbird` — **change this**
in `bib/config.toml` (generate a hash with `mkpasswd -m sha512` or
`openssl passwd -6`, or switch to an SSH `key`).

## How the awzmlinux config was ported

This variant ports `../arkane/arkdep-build.d/awzmlinux` to Fedora as closely as
practical:

- **Packages** — `package.list` is the same grouped list with Fedora/dnf names.
  Packages from RPM Fusion or COPR are annotated; Arch/arkdep-only packages
  (`arkdep`, `archiso`, `pacman-contrib`, `libnss-extrausers`, …) are dropped.
- **Overlays** — the `/etc` and `/usr` configs (keyd, seatd, udev rules for
  OpenRGB/controllers/Wooting/DFU, sysctl, GNOME dconf, Sway/Hyprland helpers,
  `sway-egpu`, `suspend-hyprland`) are carried over verbatim where they are
  distro-agnostic.
- **Sway is the default window manager.** GDM is the login manager and
  `post_install.sh` presets the installer user's default session to Sway via
  AccountsService (`gnome-shell` stays installed only because the GDM greeter
  uses it). Change `HUMMINGBIRD_DEFAULT_USER` / `HUMMINGBIRD_DEFAULT_SESSION`
  (e.g. to `hyprland`) to override; keep `HUMMINGBIRD_DEFAULT_USER` in sync with
  the user in `bib/config.toml`.
- **AUR / Chaotic-AUR** → **RPM Fusion + COPR** (`extensions/pre_build.sh`,
  `copr.list`).
- **`pip install --user`** → **`uv tool install`** on first login
  (`python-tools.list` + a user service), honouring "use uv, not pip".
- **Flatpaks** are installed by a first-boot service (flatpak needs a writable
  `/var`, which only exists on the deployed system).

### Intentional differences from arkdep

- No `abin`/`pacman`/`arkane-readonly` wrappers: immutability and transient
  package layering are handled natively by **bootc** (`bootc usroverlay`,
  `bootc switch`, atomic image updates) instead of arkdep's Btrfs read-only
  subvolumes.
- No `libnss-extrausers`/custom `nsswitch.conf`: bootc uses standard user
  management.
- `update.sh` (arkdep boot-entry migration) has no analogue: Hummingbird updates
  are atomic image pulls via `bootc upgrade`.

## After installation

On the installed system:

- Update the OS:        `sudo bootc upgrade`
- Rebase to another ref: `sudo bootc switch <registry>/<repo>:<tag>`
- Temporarily layer a package: `sudo bootc usroverlay` then `dnf install …`

**Automatic updates:** the base image enables `bootc-fetch-apply-updates.timer`,
so the system periodically pulls and atomically applies newer published images on
the next boot (the previous deployment stays available for rollback). Disable
with `sudo systemctl disable --now bootc-fetch-apply-updates.timer`.
