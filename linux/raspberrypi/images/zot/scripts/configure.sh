#!/usr/bin/env bash
#
# configure.sh — zot flavor configuration, run by the Containerfile after the
# packages and overlay are in place.
#
# As with the s3 flavors there is nothing to enable: the deployment is one
# Quadlet plus a config file plus a setup script. What this does is make the
# failure modes loud at BUILD time rather than on a headless device you have to
# physically reach — and, unlike the other flavors, refuse outright if the image
# was built on the wrong base.
set -euo pipefail

info() { printf '\e[1;32m-->\e[0m\e[1m %s\e[0m\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }
die() { printf '\e[1;31m!! %s\e[0m\n' "$*" >&2; exit 1; }

quadlet=/usr/share/containers/systemd/zot.container
config=/etc/zot/config.json

# --- The parent layer -----------------------------------------------------
# This flavor stacks on s3-garage (images/zot/parent), and ./fedora-build builds
# that chain for you. Built FROM the plain base instead — a hand-rolled
# `podman build --build-arg BASE=localhost/fedora-rpi5:latest`, say — the image
# would come out looking fine and boot into a registry with no storage behind
# it. That is worth failing the build over, not warning about.
[[ -e /usr/share/containers/systemd/garage.container ]] \
	|| die "no garage.container: this layer must be built FROM the s3-garage flavor (use ./fedora-build zot, which follows images/zot/parent)"
[[ -x /usr/libexec/garage-setup ]] \
	|| die "no /usr/libexec/garage-setup: the s3-garage layer is incomplete, so there would be no S3 credentials for the registry to use"

# --- Service enablement ---------------------------------------------------
# Nothing is enabled here, deliberately: zot.service does not exist as a file.
# Quadlet generates it at boot and applies the [Install] section from
# zot.container itself, so the .wants symlink this image uses elsewhere would
# dangle. See the comment at the top of zot.container.

# --- Sanity checks --------------------------------------------------------
for chk in \
	"podman (runs both servers):/usr/bin/podman" \
	"setup script:/usr/libexec/zot-setup" \
	"registry config:$config" \
	"Quadlet unit:$quadlet" \
	"htpasswd (mints the admin account):/usr/bin/htpasswd" \
	"skopeo (smoke-test the registry):/usr/bin/skopeo" \
	"jq:/usr/bin/jq"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || warn "MISSING: $name ($path) — check the install log above"
done

chmod 0755 /usr/libexec/zot-setup

gen=/usr/lib/systemd/system-generators/podman-system-generator
[[ -x $gen ]] || warn "MISSING: $gen — Quadlet files are ignored and neither server will start"

# A Quadlet with no [Install] silently never starts at boot.
grep -q '^\[Install\]' "$quadlet" \
	|| warn "zot.container has no [Install] section — the registry will NOT start at boot"

# The registry has no storage of its own, so it must start after Garage — but
# NOT with Requires=: when garage.service fails its first start (bad clock, failed
# pull), Requires= cancels zot's job permanently and Restart= never gets a chance.
grep -q '^Wants=garage.service' "$quadlet" \
	|| warn "zot.container does not Want= garage.service — the registry would start with no storage behind it"
grep -q '^Requires=garage.service' "$quadlet" \
	&& warn "zot.container uses Requires=garage.service — one failed Garage start at boot cancels the registry's job for good; use Wants= plus After=" \
	|| true
grep -q '^After=garage.service' "$quadlet" \
	|| warn "zot.container is not ordered After= garage.service — zot-setup would race the credentials Garage writes"

# Unlike Garage's image this one HAS an entrypoint, so Exec= is appended to it.
grep -q '^Exec=serve ' "$quadlet" \
	|| warn "zot.container Exec= does not name the config (expected 'serve /etc/zot/config.json')"

# The minimal image silently IGNORES the extensions block — no search, no UI —
# and the failure mode is a web page that never appears, with nothing in the log.
grep -q '^Image=.*zot-minimal' "$quadlet" \
	&& warn "zot.container uses the MINIMAL image, which ignores the extensions block — the web UI will silently not exist" \
	|| true
grep -qE '^Image=.*zot-linux-arm64:v[0-9]' "$quadlet" \
	|| warn "zot.container does not pin an arm64 zot version tag — this is a Pi 5, and :latest is not a deployment strategy"

# --- The registry config --------------------------------------------------
# JSON carries no comments, so everything worth knowing about this file is
# checked here and explained in README.md.
if [[ -f $config ]]; then
	jq -e . "$config" >/dev/null 2>&1 || die "$config is not valid JSON — zot would exit at every start"

	# Garage cannot do virtual-hosted-style addressing without wildcard DNS, which
	# a LAN appliance does not have. The driver defaults this to FALSE, so leaving
	# it out gives bucket.127.0.0.1:9000 and every request fails.
	[[ $(jq -r '.storage.storageDriver.forcepathstyle' "$config") == true ]] \
		|| warn "storageDriver.forcepathstyle is not true — the S3 driver would use virtual-host addressing, which needs DNS Garage does not have"

	[[ $(jq -r '.storage.storageDriver.name' "$config") == s3 ]] \
		|| warn "storageDriver.name is not \"s3\" — the registry would store blobs on the SD card instead of in Garage"

	# Plain HTTP to a loopback endpoint: 'secure' means TLS to the S3 API here.
	[[ $(jq -r '.storage.storageDriver.secure' "$config") == false ]] \
		|| warn "storageDriver.secure is not false — Garage serves plain HTTP, so TLS to it cannot work"

	# A secret in an image is a secret in every registry that image is pushed to;
	# the S3 keys come from /etc/zot/env, written on the device by zot-setup.
	[[ $(jq -r '.storage.storageDriver | has("accesskey") or has("secretkey")' "$config") == false ]] \
		|| die "SECRET IN THE IMAGE: config.json sets accesskey/secretkey — they belong in /etc/zot/env, generated on the device"

	# An unauthenticated registry on a LAN is a registry anyone can push to.
	[[ $(jq -r '.http.auth.htpasswd.path // empty' "$config") == /etc/zot/htpasswd ]] \
		|| warn "no htpasswd auth in config.json — zot allows ANY anonymous client to push when no auth is configured"

	# The port the whole README and the skopeo examples assume.
	[[ $(jq -r '.http.port' "$config") == 5000 ]] \
		|| warn "config.json does not serve on port 5000 — check README.md and zot.container agree with it"

	# The local directory is scratch and derived metadata; it must not collide
	# with Garage's own volume, which is a different disk entirely.
	root=$(jq -r '.storage.rootDirectory' "$config")
	[[ $root == /var/lib/zot ]] \
		|| warn "storage.rootDirectory is $root, but zot.container mounts /var/lib/zot — they have drifted apart"
fi

# The endpoint has to be Garage's PUBLISHED port, because zot.container uses host
# networking rather than a shared podman network. Both halves have to agree.
endpoint=$(jq -r '.storage.storageDriver.regionendpoint' "$config" 2>/dev/null || echo)
if grep -q '^Network=host' "$quadlet"; then
	[[ $endpoint == http://127.0.0.1:* ]] \
		|| warn "zot uses host networking but the S3 endpoint is $endpoint — on the host netns Garage is reachable at 127.0.0.1, not by container name"
	port=${endpoint##*:}
	grep -q "^PublishPort=${port}:" /usr/share/containers/systemd/garage.container \
		|| warn "the S3 endpoint is port $port but garage.container does not publish it — the registry would talk to nothing"
else
	warn "zot.container is not on host networking — make sure it shares a podman network with Garage, or the S3 endpoint is unreachable"
fi

info "zot flavor configure complete"
