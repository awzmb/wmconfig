# Environment

You run inside a rootless container, not on the user's machine.
Consequences:

- The filesystem, processes and network you see are the container's, not the host's.
  You cannot inspect, change or restart anything on the host.
- You are the non-root user `dev`. There is no `sudo`. `apk add` will fail — do not
  try to install system packages. If a tool is missing, say so and suggest adding it
  to the Dockerfile instead of working around it. (`apk add` *inside* a nested
  podman container is fine — that container has its own root.)
- There is no Docker daemon, no systemd, no kubectl and no cluster access unless the
  user has explicitly mounted credentials.
- Nested containers are available through rootless `podman` (see below). There is
  still no `docker` command and no daemon.
- Anything outside the mounted working directory is throwaway and disappears when the
  container exits.
- Network access is restricted to the hosts in `allowedUrls` in `settings.json`.

# Available tools

Only these are installed (from the Dockerfile). Assume nothing else exists:

`bash`, `curl`, `ca-certificates`, `openssl`, `git`, `gh`, `copilot`,
`make`, `cmake`, `gcc`, `glibc`, `go`, `golangci-lint`,
`rust` (`cargo`, `rustc`), `rust-analyzer`,
`nodejs` (`node`, `npm`), `yarn`, `uv`, `python3`
`helm`, `helm-docs`, `kustomize`, `opentofu` (`tofu`), `terragrunt`,
`jq`, `yq`, `tzdata`, `shadow`,
`podman` (rootless, nested containers).

Notes:
- Terraform is **not** installed — use `tofu`.
- Python is **not** installed as a system package — use `uv run` / `uv python install`.
- Check with `command -v <tool>` before assuming; the Dockerfile is the source of truth.

# Rootless Podman

`podman` runs nested containers as `dev`, without a daemon and without root:

- `podman pull` works (given the `force_mask` setting below). `podman run` needs an
  openable `/dev/fuse` on top of that — see "Device and storage restrictions".
  Networking uses `pasta`, storage uses `fuse-overlayfs`.
- Unqualified image names resolve against Docker Hub (`ubuntu` → `docker.io/library/ubuntu`).
- There is no `docker` command and no compose provider. Translate `docker ...`
  invocations to `podman ...`; for compose files, run the services individually or
  ask the user.
- Image pulls go over the network, so the registry must be in `allowedUrls`.
- Images and layers live in `/var/lib/containers`, outside the working directory:
  they are throwaway and disappear with the container.
- Never retry a failing `podman` command with `--privileged` or as root. The outer
  container has no capabilities at all (`CapEff=0`), so it cannot work.

## Device and storage restrictions

Two separate things must both hold: the host must pass `--device /dev/fuse
--device /dev/net/tun`, **and** those device nodes must be openable by the
container user. Check both — `ls -l /dev/fuse /dev/net/tun` — before debugging.
Passed-but-unopenable is the easy trap: the nodes appear as `crw------- root root`,
so `dev` cannot open them and you get `fuse: failed to open /dev/fuse: Permission
denied` even though the device is "there". Fixing that is host-side (make the nodes
group- or world-accessible); nothing inside the container can.

## Image unpack requires `force_mask`

Any `podman pull` fails with:

```
setting up pivot dir: mkdir ./.pivot_root...: permission denied
```

unless `force_mask` is set in `storage.conf`. Image layers contain directories
without an owner write bit (mode `0555`), and the unpacker must create a temporary
dir inside them. Normally `CAP_DAC_OVERRIDE` covers this, but **it does not work
here**: podman's user namespace has a full capability set (`CapEff` all bits) and
DAC override is still refused, because capabilities in a nested user namespace do
not override DAC on a superblock owned by an ancestor namespace. Verify with:

```
podman unshare sh -c 'mkdir -p /tmp/t; chmod 0555 /tmp/t; mkdir /tmp/t/x'
```

This is driver-independent — it is **not** a fuse or `/dev/fuse` problem, and it
fails identically on overlay and vfs. `/home/awzm/.config/containers/storage.conf`
sets `force_mask = 0o755` and is what makes pulls work.

- The value must be a TOML integer (`0o755`). A quoted string fails to decode.
- **The vfs driver rejects `force_mask`** (`unknown option "force_mask"`), so vfs is
  not a usable fallback here despite needing no fuse. Overlay is the only driver
  that works, which means `/dev/fuse` must be openable for containers to actually
  run — pulls succeed without it, `podman run` does not.
- The user config **replaces** `/etc/containers/storage.conf` rather than merging,
  so it has to repeat `driver`, `runroot`, `graphroot` and `mount_program` too.
- A store caches its `mount_program` choice, so changing that setting has no effect
  on an existing graphroot — point at a fresh one to re-probe.

| Missing | Symptom | Workaround |
|---|---|---|
| `/dev/fuse` | `fuse-overlayfs: cannot mount` / `failed to open /dev/fuse` | none that works — vfs cannot unpack (see above) |
| `/dev/net/tun` | `pasta failed ... Failed to open() /dev/net/tun` | `--network host` only; no bridge networks, no port mapping |

The outer container's `/proc` is masked, which blocks `crun` from mounting a fresh
`proc`, `devpts` and `cgroup2` in a nested user namespace. Sharing those namespaces
with the outer container is the only way through:

```
podman run --network host --pid host --cgroupns host --uts host \
  --security-opt label=disable --security-opt unmask=all \
  -v /dev/pts:/dev/pts -v /sys/fs/cgroup:/sys/fs/cgroup <image>
```

Also note:

- `podman build` fails — it overlay-mounts the build context regardless of storage
  driver. Use `podman run` against a prebuilt image instead of building locally.
- `driver_priority = ["overlay", "vfs"]` in `storage.conf` does **not** help: the
  overlay driver initialises fine and only fails at mount time, so the fallback
  never triggers. The driver has to be chosen up front.
- The Dockerfile entrypoint falls back to `STORAGE_DRIVER=vfs` when `/dev/fuse` is
  absent. That fallback is **ineffective** — vfs rejects `force_mask` and so cannot
  unpack images at all. Do not rely on it.
- `STORAGE_DRIVER` is silently ignored once a store exists; the driver is recorded
  in the store's `db.sql`. `--storage-driver` is at least loud about the mismatch.
- `podman system reset` is destructive and does not fix any of this — it wipes all
  cached images and forces a re-pull. Do not reach for it.
- Images are pulled fresh per store, so a driver switch means re-pulling everything.

### Security cost — state it when you use these flags

Those flags are not cosmetic. `--pid host` and `--network host` put the nested
container in the outer container's PID and network namespaces, so it is a *peer* of
this container, not a child: it can read every process cmdline here, signal those
processes, and bind any port. It still cannot reach the host (outer `CapEff=0` and
seccomp hold), and `/proc/<pid>/environ` stays unreadable only because the subuid
map puts nested root at a different uid. Treat the nested container as inside the
trust boundary, never as a sandbox for untrusted code, and tell the user you had to
drop isolation rather than doing it silently.
