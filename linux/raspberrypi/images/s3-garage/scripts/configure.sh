#!/usr/bin/env bash
#
# configure.sh — s3-garage flavor configuration, run by the Containerfile after
# the packages and overlay are in place.
#
# There is almost nothing to do here, and that is the point: the whole deployment
# is four declarative files in the overlay (a Quadlet, garage.toml, a .mount and a
# one-shot format unit) plus one setup script. This only makes the failure modes
# loud at BUILD time instead of at 3am on a device you have to physically reach.
set -euo pipefail

info() { printf '\e[1;32m-->\e[0m\e[1m %s\e[0m\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }

# --- Service enablement ---------------------------------------------------
# Nothing is enabled here, deliberately:
#
#   * garage.service does not exist as a file — Quadlet generates it at boot and
#     applies the [Install] section from garage.container itself. A .wants symlink
#     in /usr, which is how the rest of this image enables units offline, would
#     point at nothing. See the comment at the top of garage.container.
#   * var-lib-garage.mount is pulled in by garage.service's Requires=, so a
#     missing or blank NVMe fails the server instead of the boot.
#   * garage-format.service is pulled in by the mount.

# --- Sanity checks --------------------------------------------------------
# systemd-makefs is what actually formats the NVMe. It is a private libexec
# binary, so confirm the path this Fedora build uses really exists rather than
# discovering the typo on first boot.
makefs=/usr/lib/systemd/systemd-makefs
[[ -x $makefs ]] || warn "MISSING: $makefs — the NVMe will never be formatted; find the real path with 'rpm -ql systemd | grep makefs'"

for chk in \
	"mkfs.xfs (systemd-makefs calls it):/usr/sbin/mkfs.xfs" \
	"blkid (guards the format step):/usr/sbin/blkid" \
	"podman (runs the server):/usr/bin/podman" \
	"setup script:/usr/libexec/garage-setup" \
	"garage CLI wrapper:/usr/bin/garage" \
	"server config:/etc/garage.toml" \
	"Quadlet unit:/usr/share/containers/systemd/garage.container" \
	"mount unit:/usr/lib/systemd/system/var-lib-garage.mount" \
	"format unit:/usr/lib/systemd/system/garage-format.service"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || warn "MISSING: $name ($path) — check the install log above"
done

chmod 0755 /usr/libexec/garage-setup /usr/bin/garage

# The Quadlet is inert without the generator; podman ships it, but weak deps are
# off image-wide, so check rather than assume.
gen=/usr/lib/systemd/system-generators/podman-system-generator
[[ -x $gen ]] || warn "MISSING: $gen — Quadlet files are ignored and Garage will never start"

# A Quadlet with no [Install] silently never starts at boot: the generator only
# creates the .wants symlink if the section is there.
grep -q '^\[Install\]' /usr/share/containers/systemd/garage.container \
	|| warn "garage.container has no [Install] section — Garage will NOT start at boot"

# The image is FROM scratch with a CMD and no ENTRYPOINT, so Exec= REPLACES the
# command instead of being appended to it. Omit the /garage binary path and the
# container starts nothing.
grep -q '^Exec=/garage server' /usr/share/containers/systemd/garage.container \
	|| warn "garage.container Exec= does not begin with the /garage binary — the image has no ENTRYPOINT, so args replace the command"

# --single-node does the layout bootstrap that would otherwise be a manual
# `garage layout assign` + `layout apply` after every fresh install.
grep -q -- '--single-node' /usr/share/containers/systemd/garage.container \
	|| warn "garage.container is missing --single-node — the node boots with NO ROLE and serves nothing until you assign a layout by hand"

# The paths in the config MUST match the ones garage-setup creates and the mount
# point the volume lands on; Garage exits if either directory is missing.
for d in /var/lib/garage/meta /var/lib/garage/data; do
	grep -q "\"$d\"" /etc/garage.toml \
		|| warn "garage.toml does not reference $d — the setup script and the config have drifted apart"
done

# sqlite over the lmdb default is a deliberate durability choice for a machine
# that gets unplugged; see the comment in garage.toml.
grep -q '^db_engine *= *"sqlite"' /etc/garage.toml \
	|| warn "garage.toml is not using db_engine = sqlite — LMDB corrupts on power loss and there is no replica to recover from at replication_factor 1"

# A secret in an image is a secret in every registry that image is pushed to.
grep -qE '^ *(rpc_secret|admin_token|metrics_token) *=' /etc/garage.toml \
	&& warn "SECRET IN THE IMAGE: garage.toml sets a secret inline — it belongs in /etc/garage/env, generated on the device" \
	|| true

info "s3-garage flavor configure complete"
