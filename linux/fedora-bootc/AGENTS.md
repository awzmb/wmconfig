# AGENTS.md

Guidance for AI agents working in this repo.

## What this is

Scripts that build a custom **Fedora** — a `bootc` / image-mode Fedora desktop
image — and turn it into a bootable USB installer. The build is **two layers**: a
shared DE-agnostic **base** image and a thin **flavor** layer that adds a desktop.
Each layer is driven by one **Containerfile** with declarative config next to it.

## Layout

```
fedora-build                       # build base + selected flavor (podman build)
fedora-usb                         # build installer ISO/raw + flash to USB (bib)
flavors/
├── base/                          # shared foundation -> localhost/fedora-base
│   ├── Containerfile                   # FROM rawhide + all base build steps
│   ├── package.list                    # DE-agnostic dnf packages
│   ├── package-remove.list             # packages removed in configure.sh
│   ├── flatpak.list                    # flatpaks installed on first boot
│   ├── overlay/                        # base rootfs overlay, cp -a'd onto /
│   ├── scripts/setup-repos.sh          # RPM Fusion + Tailscale (before packages)
│   ├── scripts/configure.sh            # services, locale, plymouth, initramfs
│   └── bib/config.toml                 # bootc-image-builder config (shared)
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
sudo ./fedora-usb kde                # build installer ISO for a flavor into ./target
sudo ./fedora-usb --device /dev/sdX  # ...and flash it (DESTRUCTIVE)
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
- **Overlay is applied once per layer, after that layer's packages, before its
  `configure.sh`** so our files win over package-shipped ones and the
  dracut.conf.d/units are present when `configure.sh` runs.
- **Plymouth is set up declaratively**: the `plymouth crypt lvm dm` dracut modules
  are declared in `base/overlay/etc/dracut.conf.d/fedora.conf`
  (`add_dracutmodules`); base `configure.sh` selects the theme, writes
  `rhgb quiet` kargs (`/usr/lib/bootc/kargs.d`) and regenerates the initramfs.
  `bib/config.toml` ALSO appends `rhgb quiet` via `bootloader --append` (Anaconda
  doesn't honor bootc kargs.d). crypt/lvm/dm are needed to unlock the LUKS root.
- **Display manager + default session are per-flavor** (gnome-sway/gnome → GDM,
  kde → SDDM); the base sets no DM. Enablement is static.
- **Service enablement is static** (`.wants` symlinks written into `/usr`), because
  `systemctl enable` is unreliable in an offline image build. Keep that pattern.
- **Install-time disk encryption + user creation live in the kickstart** in
  `flavors/base/bib/config.toml` — shared by all flavors (bib has no native LUKS
  knob, and kickstart can't coexist with a `[[customizations.user]]` block). Keep
  the LUKS passphrase == the user password.

## Conventions

- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, tab indentation, colored
  `info`/`die` helpers as in the existing scripts.
- Mark deliberate simplifications/known ceilings with a `# ponytail:` comment.
- Python tooling uses **uv**, never pip.
- Do NOT `git commit` — leave committing to the user.
