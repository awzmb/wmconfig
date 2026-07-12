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

Runs as **root**: bib needs a privileged container that can relabel SELinux for
its build store, which a rootless user namespace can't do on an enforcing-SELinux
host (rootless bib fails with `chcon ... /store: Operation not permitted`). To
avoid a slow multi-GB image copy, build the image rootful too — `sudo
./fedora-build <flavor>` puts it straight into root storage, which `fedora-usb`
then uses directly (it reports "using image already in root storage — no copy
needed"). A rootless build still works but gets copied into root storage first.

| Option            | Default                                            | Notes                                  |
| ----------------- | -------------------------------------------------- | -------------------------------------- |
| `--type`          | `anaconda-iso`                                     | also `raw`, `qcow2`                    |
| `--rootfs`        | `xfs`                                              | root filesystem: `xfs`, `ext4`, `btrfs` |
| `--image`         | `localhost/fedora-<flavor>:latest`                 | image built by `fedora-build`     |
| `--config`        | `flavors/base/bib/config.toml`                     | bootc-image-builder config (shared)    |
| `--output`        | `./target`                                         | where artifacts are written           |
| `--device`        | (none)                                             | USB block device to flash, e.g. `/dev/sdb` |
| `--yes`           | off                                                | skip the flash confirmation prompt     |

`anaconda-iso` produces an installer ISO — the recommended way to install Fedora
on bare metal. bib builds the Anaconda installer straight from the bootc image
and **embeds the kickstart** from `config.toml` (full-disk LUKS + user creation).
This works because the base is a standard Fedora image (os-release `ID` `fedora`).

The kickstart is only processed for `anaconda-iso`; the lower-level
`bootc-installer` type ignores it, so Anaconda aborts at install with
`/run/install/ks.cfg is missing` — which is why `anaconda-iso` is the default.
Without `--device`, the artifact is left in `./target` and the exact `dd` command
is printed.

The default installer user is `awzm` / password `fedora` — **change this**
in `flavors/base/bib/config.toml` (generate a hash with `mkpasswd -m sha512` or
`openssl passwd -6`, or switch to an SSH `key`).

## Updating an installed system

Once installed, update in place without reflashing — rebuild the image locally
and stage it as the next boot:

```sh
sudo ./fedora-update [--apply] [flavor]   # default flavor: gnome-sway
```

This rebuilds `localhost/fedora-<flavor>:latest` into root's podman storage
(`fedora-build`) and then runs
`bootc switch --transport containers-storage localhost/fedora-<flavor>:latest`
to deploy it for the next boot. It's rootful because `bootc` runs as root and
reads root's storage.

- **Apply:** reboot to boot the new image, or pass `--apply` to reboot
  automatically once staged.
- **Roll back:** if the new image misbehaves, `sudo bootc rollback && sudo
  systemctl reboot` returns to the previous deployment.
- **Iterate faster:** `sudo FEDORA_SKIP_BASE=1 ./fedora-update` reuses the
  existing base and only rebuilds the flavor layer.

Because the source is the local `containers-storage`, no registry is involved —
`fedora-update` re-reads whatever you just built each time.

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
updates is to **build a small derived image and switch to it** — the same
`Containerfile` + `podman build` flow this repo already uses:

```sh
# derived.Containerfile
FROM <registry>/<repo>:latest       # your published image
RUN dnf install -y htop neovim && dnf clean all
```

```sh
podman build -t localhost/fedora-local:latest -f derived.Containerfile .
sudo bootc switch --transport containers-storage localhost/fedora-local:latest
reboot
```

Rebuild the derived image whenever you want to pull upstream OS updates (change
the `FROM` tag / re-pull, then rebuild). For a quick **transient** change (gone on
next boot), use `sudo bootc usroverlay` then `dnf install …`.

### Silverblue → bootc cheat sheet

| Silverblue (`rpm-ostree`)        | Fedora (`bootc`)                                       |
| -------------------------------- | ----------------------------------------------------- |
| `rpm-ostree upgrade`             | `bootc upgrade`                                        |
| `rpm-ostree rebase <ref>`        | `bootc switch <ref>`                                   |
| `rpm-ostree install <pkg>`       | derived image (`FROM` + `RUN dnf install`) + `bootc switch` |
| `rpm-ostree status`              | `bootc status`                                         |
| `rpm-ostree rollback`            | `bootc rollback`                                       |
| `rpm-ostree install` (one-shot)  | `bootc usroverlay` + `dnf install` (transient)         |

