# `s3-garage`

Single-node S3 on the Pi 5: [Garage] on XFS on the NVMe, port 9000. A real
object store — compression, dedup, and a path to a real cluster later.
**Objects are not recoverable without Garage** (chunked, content-addressed, key
mapping in the metadata DB).

## Build, flash, use

```sh
sudo ./fedora-build s3-garage --hostname s3-01 --ssh-key ~/.ssh/id_ed25519.pub
sudo ./fedora-image s3-garage --device /dev/mmcblk0     # DESTRUCTIVE
# on the device, after first boot:
sudo cat /etc/garage/env         # access key, secret key, bucket
```

First boot formats the blank NVMe, mounts it at `/var/lib/garage`, generates
secrets and starts Garage, which creates its own layout, key and a `default`
bucket (`--single-node --default-bucket`). No bootstrap commands.

```sh
aws --endpoint-url http://s3-01:9000 s3 sync ./photos s3://default/photos
sudo garage status          # /usr/bin/garage is a podman exec wrapper
sudo garage bucket list
sudo garage meta snapshot   # the only consistent metadata backup
```

## Files

| Path | What |
|------|------|
| `/usr/share/containers/systemd/garage.container` | Quadlet — the whole deployment |
| `/etc/garage.toml` | server config, yours to edit, **no secrets** |
| `/usr/lib/systemd/system/var-lib-garage.mount` | the NVMe, pulled in only by `garage.service` |
| `/usr/lib/systemd/system/garage-format.service` | `systemd-makefs xfs /dev/nvme0n1`, once |
| `/usr/libexec/garage-setup` | meta/data dirs + `/etc/garage/env` on first start |
| `/usr/bin/garage` | `podman exec garage /garage "$@"` |

## Gotchas

* `systemctl enable garage` **cannot work** — Quadlet; `[Install]` inside
  `garage.container` is the enablement.
* The image is `FROM scratch` with no ENTRYPOINT, so `Exec=` must start with
  `/garage`.
* `db_engine = "sqlite"` + `metadata_fsync`/`data_fsync` are deliberate: LMDB
  corrupts on unclean shutdown and there is no peer to rebuild from.
* `replication_factor = 1` — one copy. Back it up; snapshot the metadata off-box.
* Metadata dirs are architecture-specific; never `cp` a running node's meta dir.
* Formatting is guarded twice (`systemd-makefs` + `ExecCondition` on `PTTYPE`).
  `/dev/nvme0n1` is hard-coded.
* Tag pinned to `v2.3.0`: `--single-node` needs 2.3.0, and 2.2.0 fixed a SIGILL
  on ARM. v2.x point upgrades need no migration; major bumps need `garage migrate`.
* Plain HTTP, no TLS, no server-side encryption.

Garage vs versity, and the full notes:
[`../../README.md`](../../README.md#the-s3-garage-flavor).

[Garage]: https://garagehq.deuxfleurs.fr/
