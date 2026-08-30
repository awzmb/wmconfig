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
images/
├── base/                     # the base layer — `./fedora-build`
│   ├── Containerfile         # FROM fedora-bootc + the single build RUN
│   ├── package.list          # packages to layer (keep it short)
│   ├── authorized_keys       # OPTIONAL: SSH key, if you prefer a file to --ssh-key
│   ├── overlay/              # rootfs overlay, cp -a'd onto /
│   └── scripts/configure.sh  # Pi firmware, user, services, kargs
├── cephfs/                   # FROM the base — `./fedora-build cephfs`
│   ├── Containerfile         # Ceph node with the NVMe as an OSD
│   ├── package.list
│   ├── overlay/              # /etc/sysctl.d/90-ceph.conf, /etc/ceph/cluster.yaml
│   └── scripts/configure.sh
├── s3-versity/               # FROM the base — `./fedora-build s3-versity`
│   ├── Containerfile         # versitygw: buckets are directories on the NVMe
│   ├── package.list
│   ├── overlay/              # the Quadlet + the mount and format units
│   └── scripts/configure.sh
├── s3-garage/                # FROM the base — `./fedora-build s3-garage`
│   ├── Containerfile         # Garage: content-addressed object store on the NVMe
│   ├── package.list
│   ├── overlay/              # the Quadlet, garage.toml, mount + format units
│   └── scripts/configure.sh
└── zot/                      # FROM s3-garage — `./fedora-build zot`
    ├── parent                # "s3-garage": this layer stacks on that FLAVOR
    ├── Containerfile         # zot: an OCI registry whose blobs live in Garage
    ├── package.list
    ├── overlay/              # the Quadlet + zot's config
    └── scripts/configure.sh
```

## Quick start

```sh
# build a Ceph node called cephfs01, reachable with your key (no prompts)
sudo ./fedora-build cephfs --hostname cephfs01 --ssh-key ~/.ssh/id_ed25519.pub

sudo ./test.sh localhost/fedora-rpi5-cephfs:latest
sudo ./fedora-image cephfs --device /dev/mmcblk0    # write the SD card (DESTRUCTIVE)
```

Omit `--hostname`/`--ssh-key` and it asks for both. `sudo ./fedora-build` on its
own builds the plain base image (`localhost/fedora-rpi5:latest`).

Then boot the Pi and `ssh core@cephfs01`.

`fedora-build` asks for the **hostname** and an **SSH public key** and bakes both
in (`--hostname` / `--ssh-key`, or `FEDORA_HOSTNAME` / `FEDORA_SSH_KEY`, to skip
the prompts). The `core` user has **no password at all** — SSH key only, with
passwordless `sudo`, and password authentication and root login disabled. That
also means the HDMI console and serial header can no longer be logged into: if
you lose the key, reflash. Ethernet comes up over DHCP on its own and announces
the hostname, so the lease shows `cephfs01` rather than `*`.

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
which a bootc image may not own. So `images/base/scripts/configure.sh`:

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
keys.

### Bringing up the cluster

Ceph already has a declarative deployment tool, so this repo does not wrap one.
The image ships **`/etc/ceph/cluster.yaml`**, a cephadm service spec describing
the whole cluster: which hosts exist, which daemons run where, and which disks
become OSDs. `ceph orch apply -i` reconciles the cluster to match it, and it is
idempotent — the *same file, same command* is how you add the second node today
and a third one later.

Flash each Pi with its own name (`./fedora-build cephfs --hostname cephfs02 …`,
or just `sudo hostnamectl set-hostname cephfs02` on first boot — `/etc` is
writable and persists). Then, **on `cephfs01` only**:

```sh
sudo cephadm bootstrap --mon-ip <cephfs01-ip> --ssh-user core
```

`--ssh-user core` is **required**: cephadm SSHes as `root` by default and this
image has no root login. It connects as `core` and `sudo`s each command instead,
which is why the `core` account has passwordless sudo.

cephadm generates its own keypair and authorizes it locally, but it cannot reach
`cephfs02` until that key is authorized there too. Do it from your workstation,
which can already reach both:

```sh
ssh core@cephfs01 sudo cat /etc/ceph/ceph.pub \
  | ssh core@cephfs02 'mkdir -p -m700 ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

Then edit the addresses in `/etc/ceph/cluster.yaml` to match your network and
apply it:

```sh
sudo ceph orch apply -i /etc/ceph/cluster.yaml
sudo ceph orch host ls        # both hosts, no "offline"
sudo ceph orch device ls      # the NVMe on each, Available=Yes
```

A spec cannot create a *filesystem* (it only places daemons), so that is one more
command — it creates the two pools and the MDS daemons together:

```sh
sudo ceph fs volume create cephfs --placement="label:mds"

# two hosts can hold two copies, no more — see "Two nodes" below
for p in cephfs.cephfs.meta cephfs.cephfs.data; do
    sudo ceph osd pool set $p size 2
    sudo ceph osd pool set $p min_size 1
done

# 16 GB, and this node also runs mon+mgr+mds: don't let autotune hand the
# single OSD ~11 GB and then squeeze everything else out.
sudo ceph config set osd osd_memory_target_autotune false
sudo ceph config set osd osd_memory_target 4G
sudo ceph config set mds mds_cache_memory_limit 2G
```

Mount it from any client:

```sh
sudo mount -t ceph admin@<fsid>.cephfs=/ /mnt/data \
     -o secretfile=/etc/ceph/ceph.client.admin.keyring
```

Adding a **third** node later needs no rebuild and no data migration: authorize
the key on it, add a `service_type: host` document to `cluster.yaml`, re-apply,
then `ceph osd pool set … size 3` / `min_size 2`. CRUSH rebalances by itself.

`cephadm bootstrap` writes `ceph.conf` and the admin keyring into `/etc/ceph`,
which is preserved across `fedora-update`, so cluster identity survives an OS
update.

### Two nodes: what it actually costs you

Be clear-eyed about this before you put data on it.

* **A two-node cluster survives no failures.** Monitors need a strict majority,
  so with two mons, losing *either* node loses quorum and the control plane
  freezes. Two mons is genuinely **worse than one** — same outage, twice the
  chance of hitting it.
* **The fix is cheap and is the single highest-value change available:** a
  **third mon needs no disks and no OSD.** Any always-on box — a VM, an old Pi,
  anything — added as a host with the `mon` label gives you a real quorum that
  survives losing a storage node. Do it as soon as you can.
* **Replication is capped at two copies.** The CRUSH failure domain is `host`,
  so with two hosts you get one copy each; that *is* `active+clean`, it is just
  the maximum. Setting `size=3` does not give you three copies — CRUSH cannot
  find a third host, so the PGs sit `active+undersized+degraded` forever.
* **`min_size` is a real choice, not a default to accept.** `min_size=1` keeps
  writing while a node is down but leaves you on a single copy with no
  redundancy; `min_size=2` stops all writes the moment either node goes away.
  Upstream discourages `min_size=1`; the honest answer is that two hosts cannot
  be made safe, so keep backups either way.
* **Erasure coding is not an option** with two hosts, and neither is stretch
  mode — that is for two *datacenters* with a tiebreaker, and it forces `size=4`.
* **One active MDS plus one standby** is right here; multi-active buys nothing.

Notes:

* **There is no `ceph-osd`/`ceph-mon`/`ceph-mds` systemd unit before you
  bootstrap, and there never will be one under those names.** The daemon RPMs
  are deliberately absent; cephadm creates per-daemon units called
  `ceph-<fsid>@osd.0.service` once a cluster exists. The `ceph.target` and
  `ceph-crash.service` you see on a fresh boot come from `ceph-common` and mean
  nothing is wrong.
* **The root filesystem must not live on the NVMe you give to Ceph.** Boot from
  the SD card and keep the NVMe raw.
* **PCIe needs no `dtparam`.** The image puts the *kernel's* mainline device tree
  on the ESP (see "Known limitations"), and mainline enables both the M.2 slot
  and RP1 in the DTB itself. `dtparam=` only works with the downstream DTB, so
  adding one here would do nothing while looking like it did something.
* **`nvme.max_host_mem_size_mb=128` is set** (via `kargs.d`). DRAM-less NVMe
  drives — the Samsung 990 EVO among them — ask for 64 MiB of Host Memory Buffer,
  the Pi 5 caps HMB at 32 MiB, and on a request over the cap the kernel disables
  HMB *entirely* rather than shrinking it. The result is IO stalls and hard
  lockups under sustained writes. Check with
  `dmesg | grep -i 'host mem'` — you want "allocated 64 MiB host memory buffer",
  not "above limit".
* **The 1 GbE NIC is the bottleneck, not the disk.** The NVMe does ~450 MB/s
  (PCIe Gen 2); the onboard Ethernet does ~118 MB/s, and with two copies a
  primary OSD must send each write out again, so expect **~55–60 MB/s of client
  writes** and ~110 MB/s of reads per node. Reach for a USB3 2.5 GbE adapter
  before you reach for PCIe Gen 3.
* **Ceph's mon/mgr state lands on the SD card** (`/var/lib/ceph`), and it is
  fsync-heavy. On a node that also runs a mon, move it to the NVMe or expect slow
  ops and a worn-out card.
* **Time sync is mandatory** — the Pi 5 has no RTC and monitors reject clock
  skew, so `chronyd` is enabled by the flavor.
* `fs.aio-max-nr` and `kernel.pid_max` are raised in
  `/etc/sysctl.d/90-ceph.conf`; the defaults will make BlueStore OSDs fail.

## The `s3-versity` flavor

A single-node S3 server, with the objects on the NVMe. Build it with
`./fedora-build s3-versity`; nothing needs configuring afterwards.

```sh
sudo ./fedora-build s3-versity --hostname s3-01 --ssh-key ~/.ssh/id_ed25519.pub
sudo ./fedora-image s3-versity --device /dev/sda
# then, on the device:
sudo cat /etc/s3/root.env      # the generated root credentials
```

On first boot the Pi formats the blank NVMe as XFS, mounts it at `/var/lib/s3`,
mints a random root secret key, and starts the S3 server on port 9000. Point any
S3 client at `http://<hostname>:9000` with the credentials from
`/etc/s3/root.env` and create buckets normally — no bucket is pre-created,
because an image cannot know which ones you want.

```sh
aws --endpoint-url http://s3-01:9000 s3 mb s3://backups
aws --endpoint-url http://s3-01:9000 s3 sync ./photos s3://backups/photos
```

### The server is versitygw, not MinIO

`minio/minio` is **archived** upstream: no more releases, and no more security
fixes. The community build had also had its admin console stripped out during
2025. It is not a defensible choice for something that holds your data.

This flavor runs [versitygw] instead (Apache-2.0, actively released, official
arm64 image). It is a *gateway*, not a storage engine: **a bucket is a directory
and an object is a file at its key path**, on ordinary XFS. That is the reason it
was picked over the alternatives:

* Your data does not need this software to be readable. If versitygw is
  abandoned in turn, `cp -a` or `rsync -X` off the NVMe recovers everything —
  there is no repair tool to run and no metadata database to salvage. **Garage**
  and **SeaweedFS** are both good, actively developed servers, but their objects
  live in opaque internal stores, so they own your data in a way this does not.
* There is nothing to bootstrap. No cluster layout, no node IDs, no admin
  token — the server is stateless, so a rebuilt image with the same NVMe just
  serves the same buckets.
* On one Pi with one disk, a distributed store's replication machinery buys you
  nothing anyway.

The trade: **per-object ACLs are not implemented and object versioning is still
experimental upstream.** Bucket policies, multipart uploads, presigned URLs,
tagging and object lock all work, which covers `aws s3`, `rclone` and `restic`.
If you need the missing pieces, Ceph RGW is the grown-up answer and is already in
this repo (`./fedora-build cephfs`) — but it is a great deal of machinery for one
Pi, which is why this flavor exists.

### How it works

Three declarative files in the image plus one setup script:

* **`s3.container`** — a podman [Quadlet]. systemd generates `s3.service`
  from it at every boot. Note that `systemctl enable s3` **cannot work** on a
  Quadlet unit (the unit is transient and lives in `/run`); the `[Install]`
  section inside the file is the enablement, and the generator applies it itself.
* **`var-lib-s3.mount`** — the NVMe. It is deliberately *not* enabled: only
  `s3.service` pulls it in, so a Pi with no NVMe still boots normally and only
  S3 fails. It also means the server can never start before the mount and quietly
  fill the SD card through an empty mount point.
* **`s3-format.service`** — runs `systemd-makefs xfs /dev/nvme0n1` once.
* **`/usr/libexec/s3-setup`** — creates the three directories and, the first
  time only, the credentials file.

Notes:

* **The disk is only ever formatted if it is genuinely blank.**
  `systemd-makefs` probes with libblkid and exits without doing anything if it
  finds a filesystem. But it probes for *filesystems*, not partition tables — so
  a disk holding an OS would look blank to it. The unit therefore has an
  `ExecCondition` that refuses any disk with a partition table. Both guards have
  to be there; neither is sufficient alone.
* **`/dev/nvme0n1` is hard-coded** — a Pi 5 has one M.2 slot. If you ever attach
  a second drive, switch the mount and format units to a
  `/dev/disk/by-id/nvme-…` path, which is the only stable name a *blank* disk
  has (it has no filesystem UUID or label until it has been formatted).
* **The NVMe holds three sibling directories**, `data/` (the buckets),
  `versions/` and `iam/`. They cannot be nested: versitygw `chdir`s into the root
  and rejects a versioning directory inside it, and anything else that lived
  under the root would show up over S3 as a bucket.
* **XFS is not incidental.** Object metadata — content type, ETag, tags, ACLs —
  is stored in user extended attributes on each file. XFS supports them with no
  mount options. When you back the store up, use `rsync -X` or `tar --xattrs`;
  a plain copy gets your bytes back but not the metadata.
* **There is no redundancy.** One disk, one copy. A dead NVMe is dead data.
  Back it up.
* **The root secret key is generated on the device**, into `/etc/s3/root.env`
  (mode 0600), and never regenerated, so it survives restarts and OS updates. It
  is not in the image — a secret in an image is a secret in every registry that
  image is ever pushed to.
* **The image tag is pinned** and `AutoUpdate=` is deliberately not set;
  unattended pulls on an appliance are a bad trade. Bump the tag in
  `s3.container` and rebuild to upgrade.
* **The server speaks plain HTTP and has no TLS.** That is fine on a trusted LAN
  and nowhere else. Put it behind a reverse proxy before exposing it.

[Quadlet]: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html
[versitygw]: https://github.com/versity/versitygw

## The `s3-garage` flavor

The other way to get S3: [Garage], an AGPLv3 object store written for exactly
this hardware — small, self-hosted, low-power, geographically scattered nodes.
Same NVMe, same port 9000, different server.

```sh
sudo ./fedora-build s3-garage --hostname s3-01 --ssh-key ~/.ssh/id_ed25519.pub
sudo ./fedora-image s3-garage --device /dev/sda
# then, on the device:
sudo cat /etc/garage/env      # the generated access key, secret key and bucket
```

On first boot the Pi formats the blank NVMe as XFS, mounts it at
`/var/lib/garage`, generates its secrets, and starts Garage — which creates its
own cluster layout, an access key and a bucket called `default`, with no
bootstrap commands to run. Then:

```sh
aws --endpoint-url http://s3-01:9000 s3 ls
aws --endpoint-url http://s3-01:9000 s3 sync ./photos s3://default/photos
```

The CLI is the same binary as the server and only exists inside the container, so
there is a small wrapper on `PATH`:

```sh
sudo garage status          # is the node up, does it have a role?
sudo garage bucket list
sudo garage key list
sudo garage meta snapshot   # metadata backup — see the warning below
```

### Garage or versity?

They solve the same problem from opposite directions, and the difference that
actually matters is **what happens to your data if the software goes away**:

* **`s3-versity` is a gateway over a normal filesystem.** A bucket is a
  directory, an object is a file at its key path. If the project dies, `cp -a`
  gets everything back.
* **`s3-garage` is a real object store.** Objects are split into 1 MiB chunks,
  compressed, deduplicated and stored as content-addressed blocks; the mapping
  from S3 key to blocks lives in a database. **You cannot recover objects from
  the data directory with `cp` or `rsync`** — you need Garage and an intact
  metadata DB. There is no documented offline export tool.

In exchange Garage gives you things a gateway cannot: real clustering (add nodes
and it replicates and rebalances across them), zone-aware placement,
deduplication, compression, block integrity checking, and its own bucket quota
and key management. It is also the more actively developed project.

Rough guide: **take `s3-versity` if this stays one box and you value being able
to walk away from the software; take `s3-garage` if you want it to grow into a
cluster, or you want compression and dedup.** Neither gives you redundancy on one
disk.

Feature-wise Garage covers multipart uploads, presigned URLs, CORS, and basic
lifecycle expiry — enough for `aws s3 sync`, `rclone` and `restic`. It does
**not** implement bucket policies, per-object ACLs (it has its own
key-per-bucket permission system instead), object versioning, object lock, or
server-side encryption.

### Read this before you trust it with data

* **`replication_factor = 1` means exactly what it says.** One node, one copy.
  Garage's own documentation says of this setting: *"There is no redundancy...
  Do not use this for anything else than test deployments."* That warning is
  about durability, not stability — single-node Garage is a documented, supported
  mode with first-class support (`--single-node`), unlike single-node Ceph which
  upstream actively discourages. But a dead NVMe is still dead data. **Back it
  up.**
* **The metadata database is the single point of failure**, and this is the part
  people get wrong. Garage's default engine is LMDB, which upstream says *"is
  prone to database corruption after an unclean shutdown (e.g. a process kill or
  a power outage)"*. On a normal cluster you would just rebuild the metadata from
  a peer. There is no peer here. So this image ships **`db_engine = "sqlite"`**
  instead, which upstream recommends when snapshots are not an option, plus
  `metadata_fsync`/`data_fsync` and an automatic metadata snapshot every 6 hours.
  Together those cost write throughput and buy you a machine that survives being
  unplugged. If the box is on a UPS and you would rather have the speed, both
  fsync settings are one edit away in `/etc/garage.toml`.
* **Take metadata snapshots off the box.** `sudo garage meta snapshot` produces a
  consistent copy (a filesystem-level copy of a running node's metadata is not
  consistent, and upstream says so). At `replication_factor = 1` this is your
  only recovery path.
* **LMDB and SQLite metadata directories are architecture-specific.** You cannot
  lift `/var/lib/garage/meta` off this Pi and open it on an x86 box.
* **The server speaks plain HTTP and has no TLS**, and Garage implements no
  server-side encryption. Fine on a trusted LAN, nowhere else. Reverse-proxy it
  before exposing it, and encrypt client-side if you care.

### How it works

Four declarative files in the image plus two small scripts:

* **`garage.container`** — a podman [Quadlet]. systemd generates `garage.service`
  from it at every boot. Note that `systemctl enable garage` **cannot work** on a
  Quadlet unit (the unit is transient and lives in `/run`); the `[Install]`
  section inside the file is the enablement, and the generator applies it itself.
* **`/etc/garage.toml`** — the server config, yours to edit; `/etc` is 3-way
  merged across `fedora-update`. It is bind-mounted read-only into the container
  at Garage's default config path. **It contains no secrets, on purpose.**
* **`var-lib-garage.mount`** — the NVMe. It is deliberately *not* enabled: only
  `garage.service` pulls it in, so a Pi with no NVMe still boots normally and only
  S3 fails. It also means the server can never start before the mount and quietly
  fill the SD card through an empty mount point.
* **`garage-format.service`** — runs `systemd-makefs xfs /dev/nvme0n1` once.
  XFS is Garage's own recommendation for the data directory; it explicitly warns
  against ext4 for inode reasons.
* **`/usr/libexec/garage-setup`** — creates the metadata and data directories
  and, the first time only, writes `/etc/garage/env` with the RPC secret and the
  initial S3 credentials.
* **`/usr/bin/garage`** — a four-line `podman exec` wrapper so the CLI is on
  `PATH` and always matches the running server version.

Notes:

* **The disk is only ever formatted if it is genuinely blank.**
  `systemd-makefs` probes with libblkid and exits without doing anything if it
  finds a filesystem. But it probes for *filesystems*, not partition tables — so
  a disk holding an OS would look blank to it. The unit therefore has an
  `ExecCondition` that refuses any disk with a partition table. Both guards have
  to be there; neither is sufficient alone.
* **`/dev/nvme0n1` is hard-coded** — a Pi 5 has one M.2 slot. If you ever attach
  a second drive, switch the mount and format units to a
  `/dev/disk/by-id/nvme-…` path, which is the only stable name a *blank* disk
  has (it has no filesystem UUID or label until it has been formatted).
* **Metadata and data share the NVMe.** Upstream blesses this explicitly for
  single-drive nodes, and an NVMe is far better than the spinning disk that
  advice was written for.
* **Credentials are generated on the device**, into `/etc/garage/env` (mode
  0600), and never regenerated, so they survive restarts and OS updates. Deleting
  that file mints a new key *and a new RPC secret* on the next start — the
  objects stay, but every client config breaks.
* **The image tag is pinned to `v2.3.0`** and `AutoUpdate=` is deliberately not
  set. Two floors matter: `--single-node` needs **v2.3.0**, and **v2.2.0** fixed
  a SIGILL crash on Raspberry Pi and older ARM boards — older tags will not run
  on this hardware at all. Bump the tag in `garage.container` and rebuild to
  upgrade; v2.x point releases need no metadata migration, major versions do.

[Quadlet]: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html
[Garage]: https://garagehq.deuxfleurs.fr/

## The `zot` flavor

An **OCI registry** on the Pi, with every blob stored in the Garage S3 service
running beside it. Both servers are podman Quadlets; the registry answers on
**:5000**, the S3 API on **:9000**, and the objects land on the NVMe.

This is the one flavor that does not build on the base image: `images/zot/parent`
says `s3-garage`, so `./fedora-build zot` builds base → s3-garage → zot in one
command and the registry inherits the whole storage layer — the format unit, the
mount, `garage.toml`, the credentials — unchanged.

```sh
sudo ./fedora-build zot --hostname registry01 --ssh-key ~/.ssh/id_ed25519.pub
sudo ./fedora-image zot --device /dev/mmcblk0
# then, on the device:
sudo cat /etc/zot/credentials      # the registry admin account
```

First boot formats the NVMe, brings up Garage (which creates its own layout, key
and `default` bucket), copies those S3 credentials into `/etc/zot/env` and starts
the registry against them. Nothing to bootstrap.

```sh
podman login registry01:5000 -u admin             # password from /etc/zot/credentials
podman push registry01:5000/myapp:v1
skopeo list-tags docker://registry01:5000/myapp   # pulls are anonymous
```

The web UI is at `http://registry01:5000/`.

### This was going to be Harbor

It cannot be. **Harbor publishes no arm64 images**: `goharbor/harbor-core` and
every sibling component are single-arch amd64, through v2.15.2, so Harbor does
not run on a Raspberry Pi at all. The only prebuilt arm64 component set is
Bitnami's `bitnamilegacy/*` catalog — frozen in August 2025, no further releases
and no security fixes — which is the same objection this repo makes against MinIO
in the `s3-versity` section, applied to the thing that holds your images. The
remaining option is building Harbor's ten component images from source on arm64,
which is a project, not a flavor.

[zot] is a CNCF registry, conformant with the OCI distribution spec, publishes a
real arm64 image, and takes the same S3 backend. What you lose against Harbor:
**projects and RBAC, replication, vulnerability scanning, signing policy and a
proxy cache.** What you keep: push/pull for `podman`, `docker`, `skopeo` and
`helm`, htpasswd auth with per-repository policies, a search UI, and pull-through
`sync` mirroring if you configure it.

### How it works

* **`zot.container`** — the Quadlet. `Requires=garage.service`, because the
  registry has no storage of its own. It uses **host networking**, which is why
  the S3 endpoint in the config is simply `127.0.0.1:9000` (Garage's published
  port) and why zot serves on `:5000` with no port mapping.
* **`/etc/zot/config.json`** — the S3 storage driver, htpasswd auth, and the
  `search`/`ui` extensions. JSON takes no comments, so the reasoning lives in
  `images/zot/scripts/configure.sh`, which re-checks each of these at build time.
* **`/usr/libexec/zot-setup`** — copies Garage's generated access key into
  `/etc/zot/env` as `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, and mints a
  random `admin` password into `/etc/zot/htpasswd` (bcrypt) and
  `/etc/zot/credentials` (plaintext, 0600, not mounted into the container).

Notes:

* **`forcepathstyle: true` is not optional.** The S3 driver defaults it to
  *false*, which means virtual-hosted-style addressing — `bucket.127.0.0.1:9000`
  — and that needs wildcard DNS no LAN appliance has. Every request fails without
  it. Garage handles the rest of what the driver needs: it implements
  `CopyObject`, `ListObjectsV2` and `UploadPartCopy`, the last of which the
  registry uses for every layer over 32 MB.
* **Use the full image, not `zot-minimal-*`.** The minimal build parses the
  `extensions` block and then ignores it, so the UI simply never appears and
  nothing in the log explains why.
* **Credentials are on the device, not in the image**, exactly like Garage's.
  Deleting `/etc/zot/htpasswd` and `/etc/zot/credentials` mints a new admin
  password on the next start; deleting `/etc/zot/env` re-reads Garage's keys.
* **With no `auth` section zot accepts anonymous pushes** from anyone who can
  reach port 5000, so the shipped config configures htpasswd auth: `admin` can
  push, anonymous clients can pull. Drop `anonymousPolicy` from `config.json` to
  require a login for pulls too.
* **`dedupe` is off.** With it on, zot keeps a local boltdb cache the S3 contents
  depend on; off, every blob stands alone in Garage and the SD card holds nothing
  but derived state. The cost is some duplicated space in the store.
* **The registry is plain HTTP**, so clients need `--tls-verify=false` (or an
  `insecure` registry entry) unless you put a TLS reverse proxy in front. Same
  caveat, and same fix, as the S3 endpoint.
* **Everything the `s3-garage` section says about durability still applies** —
  one disk, `replication_factor = 1`, and `garage meta snapshot` as the only
  metadata recovery path. A registry is not a backup.

[zot]: https://zotregistry.dev/

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

* **The ESP carries the kernel's device tree, not the firmware package's.**
  Fedora's `bcm283x-firmware` ships the *downstream* Raspberry Pi DTBs, which
  describe RP1 — the chip carrying **both USB and Ethernet** on a Pi 5 — in a way
  a mainline kernel cannot bind to. The result is a machine that boots to a login
  prompt with a dead keyboard and no network. Fedora fixes this for the Pi 3/4
  with `dtoverlay=upstream`; no such overlay exists for the Pi 5, so the build
  copies the kernel's own `bcm2712*rpi-5-b.dtb` onto the ESP instead. Side
  effect: `dtparam=` and downstream `.dtbo` overlays stop working, because both
  rely on nodes only the downstream DTBs contain. One of those overlays is the
  SoC *stepping* fixup, so the build installs mainline's D0 variant directly —
  correct for every Pi 5 Rev 1.1 and later. On an original Rev 1.0 board, set
  `pi5_soc=bcm2712-rpi-5-b` in `images/base/scripts/configure.sh`; leaving it wrong
  panics with `Asynchronous SError Interrupt` a couple of seconds into boot.

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

* **Packages** — `images/base/package.list`. The `fedora-bootc` base already ships
  systemd, dnf, bootc, coreutils, vim-minimal and openssh-clients; only add what
  it does not.
* **Files** — drop them in `images/base/overlay/`, mirroring the target paths.
* **Kernel args** — `/usr/lib/bootc/kargs.d/*.toml`, written by `configure.sh`.
* **Base image** — `FEDORA_BASE=quay.io/fedora/fedora-bootc:43 ./fedora-build`.
* **Tag** — `FEDORA_TAG=localhost/my-pi:latest`.

## Credits

The Pi firmware relocation + `bootupctl` shim pattern comes from
[ondrejbudai/fedora-bootc-raspi](https://github.com/ondrejbudai/fedora-bootc-raspi)
and [supakeen's write-up](https://supakeen.com/weblog/bootc-on-the-raspberry-pi/).
