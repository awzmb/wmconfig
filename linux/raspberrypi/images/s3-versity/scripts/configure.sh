#!/usr/bin/env bash
#
# configure.sh — s3 flavor configuration, run by the Containerfile after the
# packages and overlay are in place.
#
# There is almost nothing to do here, and that is the point: the whole deployment
# is three declarative files in the overlay (a Quadlet, a .mount and a one-shot
# format unit) plus one setup script. This only makes the failure modes loud at
# BUILD time instead of at 3am on a device you have to physically reach.
set -euo pipefail

info() { printf '\e[1;32m-->\e[0m\e[1m %s\e[0m\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }

# --- Service enablement ---------------------------------------------------
# Nothing is enabled here, deliberately:
#
#   * s3.service does not exist as a file — Quadlet generates it at boot and
#     applies the [Install] section from s3.container itself. A .wants symlink in
#     /usr, which is how the rest of this image enables units offline, would
#     point at nothing. See the comment at the top of s3.container.
#   * var-lib-s3.mount is pulled in by s3.service's Requires=, so a missing or
#     blank NVMe fails the gateway instead of the boot.
#   * s3-format.service is pulled in by the mount.

# --- Sanity checks --------------------------------------------------------
# systemd-makefs is what actually formats the NVMe. It is a private libexec
# binary, so confirm the path this Fedora build uses really exists rather than
# discovering the typo on first boot.
makefs=/usr/lib/systemd/systemd-makefs
[[ -x $makefs ]] || warn "MISSING: $makefs — the NVMe will never be formatted; find the real path with 'rpm -ql systemd | grep makefs'"

for chk in \
	"mkfs.xfs (systemd-makefs calls it):/usr/sbin/mkfs.xfs" \
	"blkid (guards the format step):/usr/sbin/blkid" \
	"getfattr (object metadata lives in xattrs):/usr/bin/getfattr" \
	"podman (runs the gateway container):/usr/bin/podman" \
	"setup script:/usr/libexec/s3-setup" \
	"Quadlet unit:/usr/share/containers/systemd/s3.container" \
	"mount unit:/usr/lib/systemd/system/var-lib-s3.mount" \
	"format unit:/usr/lib/systemd/system/s3-format.service"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || warn "MISSING: $name ($path) — check the install log above"
done

chmod 0755 /usr/libexec/s3-setup

# The Quadlet is inert without the generator; podman ships it, but weak deps are
# off image-wide, so check rather than assume.
gen=/usr/lib/systemd/system-generators/podman-system-generator
[[ -x $gen ]] || warn "MISSING: $gen — Quadlet files are ignored and the S3 server will never start"

# A Quadlet with no [Install] silently never starts at boot: the generator only
# creates the .wants symlink if the section is there.
grep -q '^\[Install\]' /usr/share/containers/systemd/s3.container \
	|| warn "s3.container has no [Install] section — the S3 server will NOT start at boot"

# versitygw parses global flags only BEFORE the backend subcommand; put --port or
# --iam-dir after `posix` and it exits with a usage error at every boot.
grep -q '^Exec=.*--iam-dir .* posix ' /usr/share/containers/systemd/s3.container \
	|| warn "s3.container Exec= puts a global flag after the 'posix' subcommand — versitygw will refuse to start"

info "s3 flavor configure complete"
