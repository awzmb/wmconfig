# `s3-versity`

Single-node S3 on the Pi 5: [versitygw] over XFS on the NVMe, port 9000.
**A bucket is a directory, an object is a file** — `cp -a`/`rsync -X` recovers
everything without the software.

## Build, flash, use

```sh
sudo ./fedora-build s3-versity --hostname s3-01 --ssh-key ~/.ssh/id_ed25519.pub
sudo ./fedora-image s3-versity --device /dev/mmcblk0    # DESTRUCTIVE
# on the device, after first boot:
sudo cat /etc/s3/root.env        # generated root credentials
```

First boot formats the blank NVMe, mounts it at `/var/lib/s3`, mints a root
secret and starts the server. Nothing to bootstrap, no bucket pre-created.

```sh
aws --endpoint-url http://s3-01:9000 s3 mb s3://backups
aws --endpoint-url http://s3-01:9000 s3 sync ./photos s3://backups/photos
systemctl status s3.service var-lib-s3.mount
```

## Files

| Path | What |
|------|------|
| `/usr/share/containers/systemd/s3.container` | Quadlet — the whole deployment |
| `/usr/lib/systemd/system/var-lib-s3.mount` | the NVMe, pulled in only by `s3.service` |
| `/usr/lib/systemd/system/s3-format.service` | `systemd-makefs xfs /dev/nvme0n1`, once |
| `/usr/libexec/s3-setup` | creates `data/ versions/ iam/`, mints `/etc/s3/root.env` |

## Gotchas

* `systemctl enable s3` **cannot work** — it is a Quadlet; the `[Install]`
  section inside `s3.container` is the enablement.
* Global flags go **before** the `posix` subcommand in `Exec=`, or it exits at
  every boot.
* Formatting is guarded twice: `systemd-makefs` skips a disk with a filesystem,
  and `ExecCondition` refuses one with a partition table. Keep both.
* `/dev/nvme0n1` is hard-coded (one M.2 slot).
* Metadata lives in xattrs — back up with `rsync -X` / `tar --xattrs`.
* One disk, no redundancy. Plain HTTP, no TLS.
* Upgrade by bumping the pinned tag in `s3.container` and rebuilding.

Why versitygw and not MinIO/Garage, and the full notes:
[`../../README.md`](../../README.md#the-s3-versity-flavor).

[versitygw]: https://github.com/versity/versitygw
