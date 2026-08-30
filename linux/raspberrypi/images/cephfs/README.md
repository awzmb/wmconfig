# `cephfs`

Ceph node for the Pi 5: OS on the SD card, **NVMe becomes an OSD**. Ships
`cephadm` + `ceph-common` only — the daemons run as podman containers from
`quay.io/ceph/ceph`.

## Build and flash

```sh
sudo ./fedora-build cephfs --hostname cephfs01 --ssh-key ~/.ssh/id_ed25519.pub
sudo ./fedora-image cephfs --device /dev/mmcblk0     # DESTRUCTIVE
```

Repeat per node with its own `--hostname` (or `hostnamectl set-hostname` on
first boot).

## Bring up the cluster

On the first node only:

```sh
sudo cephadm bootstrap --mon-ip <ip> --ssh-user core   # --ssh-user is required
```

Authorize cephadm's key on every other node, from your workstation:

```sh
ssh core@cephfs01 sudo cat /etc/ceph/ceph.pub \
  | ssh core@cephfs02 'mkdir -p -m700 ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

Edit the addresses in `/etc/ceph/cluster.yaml`, then:

```sh
sudo ceph orch apply -i /etc/ceph/cluster.yaml
sudo ceph orch host ls && sudo ceph orch device ls
sudo ceph fs volume create cephfs --placement="label:mds"
```

Adding a node later is the same file and the same command.

## Files

| Path | What |
|------|------|
| `/etc/ceph/cluster.yaml` | cephadm service spec (hosts, daemons, OSDs) |
| `/etc/sysctl.d/90-ceph.conf` | `fs.aio-max-nr`, `kernel.pid_max` — BlueStore needs them |
| `/etc/ceph/` (post-bootstrap) | fsid, `ceph.conf`, keyrings — survives `fedora-update` |

## Gotchas

* `--ssh-user core` is mandatory: this image has no root login.
* No `ceph-osd`/`ceph-mon` units exist before bootstrap, and never under those
  names — cephadm creates `ceph-<fsid>@osd.0.service`.
* Keep the NVMe raw; boot from the SD card.
* Two nodes = no fault tolerance and max 2 replicas. A **third mon** (no disks
  needed) is the highest-value fix.
* Pin OSD memory on a 16 GB converged node:
  `ceph config set osd osd_memory_target_autotune false` + `… osd_memory_target 4G`.
* Never `cephadm add-repo`/`install` — they shell out to dnf against read-only `/usr`.

Full rationale, two-node trade-offs and tuning: [`../../README.md`](../../README.md#the-cephfs-flavor).
