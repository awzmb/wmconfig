# `zot`

An OCI registry on the Pi 5: [zot] with every blob stored in the [Garage] S3
service running next to it, both as podman Quadlets. Registry on **:5000**, S3
on **:9000**, objects on the NVMe.

This layer stacks on the **`s3-garage` flavor**, not on the base — `parent` in
this directory says so and `./fedora-build zot` builds the chain in one go.

## Build, flash, use

```sh
sudo ./fedora-build zot --hostname registry01 --ssh-key ~/.ssh/id_ed25519.pub
sudo ./fedora-image zot --device /dev/mmcblk0     # DESTRUCTIVE
# on the device, after first boot:
sudo cat /etc/zot/credentials     # the registry admin password
sudo cat /etc/garage/env          # the S3 keys, if you want the store directly
```

First boot formats the blank NVMe as XFS, mounts it at `/var/lib/garage`,
starts Garage (which creates its own layout, key and `default` bucket), then
starts zot against it. Nothing to bootstrap.

```sh
podman login registry01:5000 -u admin              # password from /etc/zot/credentials
podman push registry01:5000/myapp:v1
skopeo list-tags docker://registry01:5000/myapp    # anonymous, read is open
curl -s http://registry01:5000/v2/_catalog | jq
```

The web UI (search + UI extensions, hence the full image and not
`zot-minimal-*`) is at `http://registry01:5000/`.

## Files

| Path | What |
|------|------|
| `/usr/share/containers/systemd/zot.container` | Quadlet — the registry |
| `/etc/zot/config.json` | zot config: S3 backend, auth, extensions |
| `/usr/libexec/zot-setup` | copies Garage's keys to `/etc/zot/env`, mints the admin account |
| `/etc/zot/credentials` | generated on device: the admin password |
| *(from the parent layer)* | `garage.container`, `garage.toml`, `var-lib-garage.mount`, `garage-format.service` |

## Why not Harbor

Harbor was the ask. **Harbor publishes no arm64 images** — `goharbor/harbor-core`
and all its siblings are single-arch amd64, up to and including v2.15.2, so they
cannot run on this hardware at all. The only prebuilt arm64 set is Bitnami's
`bitnamilegacy/*` catalog, frozen since Aug 2025 with no further security fixes,
which is the same objection this repo already makes against MinIO — on the
component that holds your images.

zot is CNCF, ships a real arm64 image, is conformant with the OCI distribution
spec, and speaks the same S3 backend. What you give up versus Harbor: **projects
and RBAC, replication between registries, vulnerability scanning, image signing
policy, and a proxy cache.** zot has sync (pull-through mirroring) and a search
UI, but not the rest. If you need them, run Harbor on an amd64 box.

## Gotchas

* **`Requires=` on `garage.service` is a trap, so the unit uses `Wants=`.** A
  failed Garage start at boot would otherwise cancel zot's job permanently
  ("Dependency failed for zot.service") and never retry it, leaving a running
  Garage next to a dead registry.
* **`systemctl enable zot` cannot work** — Quadlet; the `[Install]` section
  inside `zot.container` is the enablement. Same for `garage`.
* **`forcepathstyle: true` is mandatory.** The S3 driver defaults it to *false*,
  and virtual-host addressing (`bucket.127.0.0.1:9000`) needs DNS a LAN
  appliance does not have. Every request fails without it.
* The zot image **has an ENTRYPOINT** (`/usr/local/bin/zot-linux-arm64`), unlike
  Garage's FROM-scratch image, so `Exec=` is *appended* rather than replacing a
  CMD.
* **The minimal image would ignore `[extensions]` silently** — no UI, nothing in
  the log. Keep the full `zot-linux-arm64` image.
* **No auth = anonymous push.** zot allows everything when no `auth` section is
  present, so the config ships htpasswd auth: anonymous clients can pull,
  `admin` can push. Tighten by removing `anonymousPolicy` from `config.json`.
* **`dedupe` is off.** With it on, zot keeps a local boltdb cache that the S3
  contents depend on; off, every blob is self-contained in Garage and the SD card
  holds only derived state. It costs some space in the store.
* `/var/lib/zot` (scratch + derived metadata) is on the **SD card**; the registry's
  real state is in Garage on the NVMe.
* **Host networking**, so zot reaches Garage at `127.0.0.1:9000` and serves on
  `:5000` directly. Add a shared `registry.network` and use container DNS if a
  third service ever lands here.
* **One disk, no redundancy, plain HTTP.** Back the NVMe up; reverse-proxy it
  before exposing it. `sudo garage meta snapshot` is still your only metadata
  recovery path — see [`../s3-garage/README.md`](../s3-garage/README.md).

[zot]: https://zotregistry.dev/
[Garage]: https://garagehq.deuxfleurs.fr/
