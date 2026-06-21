#!/usr/bin/env bash
#
# pre_build extension.
#
# arkdep runs pre_build.sh after the Btrfs subvolumes are created but before
# bootstrap. In the bootc/Containerfile flow there is no separate bootstrap (the
# base image already exists), so we use this hook to wire up the package sources
# the ported package.list depends on.
#
# IMPORTANT: the Hummingbird base image (quay.io/hummingbird-community/bootc-os)
# follows the "distroless" philosophy and ships ONLY its own curated repo
# (public-hummingbird-*-rpms). It does NOT enable the standard Fedora repos, so a
# plain `dnf install <fedora package>` finds almost nothing. This script therefore
# adds the regular Fedora repositories (and RPM Fusion + COPR) so the full Fedora
# package set the desktop config needs becomes installable.
#
# The base ships its own `hummingbird-release` package which *provides*
# system-release. We must NOT let Fedora's own `fedora-release`/`generic-release`
# packages get pulled in, because they conflict with hummingbird-release. We
# therefore exclude them from the added repos, and install the RPM Fusion release
# packages with `rpm --nodeps` (they are just config + GPG keys, but declare a
# hard `system-release(NN)` dependency that only the conflicting Fedora release
# packages satisfy).
#
# This is the Fedora analogue of awzmlinux/extensions/post_bootstrap.sh, which
# enabled the Chaotic-AUR on Arch.
#
# Runs as root inside the image build. $variant points at the variant config.
set -euo pipefail

variant=${HUMMINGBIRD_VARIANT_DIR:-/run/hummingbird/variant}

# The Hummingbird base image is a snapshot of a SPECIFIC Fedora release (NOT
# rawhide): its installed packages are all `.fcNN` / `.hum1` builds that share one
# consistent glibc/toolchain ABI. Overlaying a *different* Fedora stream (e.g.
# rawhide) drags in packages built against a newer glibc/libxml2/libxkbcommon that
# are mutually exclusive with the base and simply cannot be installed (this broke
# not only the desktop stack but core packages like e2fsprogs/podman/kbd).
#
# We therefore detect the base's OWN Fedora release and overlay the MATCHING stable
# Fedora repositories, so the base and the overlay share one ABI and the full
# package set (including the GNOME/gdm desktop) installs cleanly.
basearch=$(rpm -E %_arch 2>/dev/null || echo x86_64)

detect_base_relver() {
	local v
	# 1. The rpm %fedora macro (set by the installed release package) is the
	#    authoritative Fedora release the base was built as.
	v=$(rpm -E %fedora 2>/dev/null || true)
	[[ $v =~ ^[0-9]+$ ]] && { echo "$v"; return; }
	# 2. Fallback: the highest `.fcNN` tag among INSTALLED packages (i.e. what the
	#    base itself was composed from, ignoring the overlay repos we add later).
	v=$(rpm -qa --qf '%{release}\n' 2>/dev/null \
		| grep -oE 'fc[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -n1 || true)
	[[ $v =~ ^[0-9]+$ ]] && { echo "$v"; return; }
	return 1
}

releasever=$(detect_base_relver || true)
if [[ ! $releasever =~ ^[0-9]+$ ]]; then
	echo "!! could not determine the base Fedora release; cannot pick a matching overlay" >&2
	exit 1
fi

# Never let Fedora's release/identity packages replace hummingbird-release.
# (Belt and braces: excluded per-repo below AND globally.)
#
# Also exclude gpgme2: the base ships legacy `gpgme` (libgpgme.so.11, hard-required
# by podman/bootc/wget2/skopeo). Some desktop packages pull `gpgme2`
# (libgpgme.so.45) as a *weak* dep; both provide /usr/bin/gpgme-json, so installing
# gpgme2 alongside gpgme is an unresolvable RPM file conflict. Nothing here hard-
# requires gpgme2, so dropping the weak dep is harmless. Remove once the base moves
# to gpgme2 (then podman/skopeo would need libgpgme.so.45 instead).
release_excludes='generic-release,fedora-release,fedora-release-*,fedora-repos,fedora-repos-*,fedora-identity-*,gpgme2'

# Make dnf resolve $releasever consistently for the rest of the build (COPR,
# RPM Fusion repo files all use $releasever).
mkdir -p /etc/dnf/vars
echo "$releasever" > /etc/dnf/vars/releasever

# --- Add the standard Fedora repositories --------------------------------
# The Hummingbird base is "distroless" and only ships its own curated repo, so we
# add the regular Fedora repositories for the MATCHING stable release ($releasever,
# detected above). A stable release has two repos: the frozen GA "fedora" repo and
# the rolling "updates" repo; we add both. Helper that (re)writes the repo file;
# the GPG key is filled in once we have resolved it.
repo_file=/etc/yum.repos.d/fedora-hummingbird-overlay.repo
write_fedora_repo() {  # $1 = gpgcheck (0/1), $2 = gpgkey value (optional)
	local gc=$1 key=${2:-}
	{
		echo '[fedora-hb]'
		echo 'name=Fedora $releasever - $basearch'
		echo 'metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch'
		echo 'enabled=1'
		echo 'countme=0'
		echo "gpgcheck=$gc"
		[[ -n $key ]] && echo "gpgkey=$key"
		echo "excludepkgs=$release_excludes"
		# Give the Hummingbird base repos priority over the Fedora overlay: when
		# BOTH repos provide a package, dnf must prefer the curated `.hum1` build.
		# Lower number = higher preference (default is 99), so the overlay sits
		# well below the Hummingbird repos, which we pin to priority=1 below.
		echo 'priority=200'
		echo 'skip_if_unavailable=False'
		echo ''
		echo '[updates-hb]'
		echo 'name=Fedora $releasever - $basearch - Updates'
		echo 'metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch'
		echo 'enabled=1'
		echo 'countme=0'
		echo "gpgcheck=$gc"
		[[ -n $key ]] && echo "gpgkey=$key"
		echo "excludepkgs=$release_excludes"
		echo 'priority=200'
		echo 'skip_if_unavailable=False'
	} > "$repo_file"
}

# Bootstrap the repos with gpgcheck disabled just long enough to read metadata
# (repository metadata is not OpenPGP-checked by default, package payloads are).
write_fedora_repo 0
printf '\e[1;32m-->\e[0m\e[1m Refreshing repositories\e[0m\n'
dnf -y makecache || true

printf '\e[1;32m-->\e[0m\e[1m Targeting Fedora %s (matching the base)\e[0m\n' "$releasever"

# Resolve the GPG key for the base's Fedora release: prefer an on-disk key (the
# base already ships Fedora's keys), else fetch the official numbered key over
# https (dnf imports it automatically). Keep gpgcheck=1 so payloads stay verified.
gpgcheck=1
gpgkey=""
if [[ -e "/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${releasever}-${basearch}" ]]; then
	gpgkey="file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${releasever}-${basearch}"
else
	alt=$(ls /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${releasever}-* 2>/dev/null | head -n1 || true)
	if [[ -n $alt ]]; then
		gpgkey="file://$alt"
	else
		gpgkey="https://src.fedoraproject.org/rpms/fedora-repos/raw/f${releasever}/f/RPM-GPG-KEY-fedora-${releasever}-primary"
		echo "-> Fedora ${releasever} GPG key not on disk; importing from ${gpgkey}"
	fi
fi

write_fedora_repo "$gpgcheck" "$gpgkey"

# --- Pin the Hummingbird base repos ABOVE the Fedora overlay --------------
# The Hummingbird base ships its own curated repos (public-hummingbird-*-rpms)
# without an explicit priority, so they sit at dnf's default (99) while we put
# the Fedora overlay at 200. To make the preference unambiguous and survive any
# future repo-id rename, bump EVERY repo whose id contains "hummingbird" to the
# highest preference (priority=1). dnf then always prefers the `.hum1` build of a
# package when one exists, and only reaches into the Fedora overlay for packages
# Hummingbird does not ship. This requires the `priorities` behaviour, which is
# built in to dnf5 and provided by dnf-plugins-core on dnf4.
printf '\e[1;32m-->\e[0m\e[1m Pinning Hummingbird repos above the Fedora overlay\e[0m\n'
for f in /etc/yum.repos.d/*.repo; do
	[[ -e $f ]] || continue
	# Only touch files that actually define a hummingbird repo id.
	grep -qiE '^\[[^]]*hummingbird[^]]*\]' "$f" || continue
	# Single pass: track whether we are inside a hummingbird section; drop any
	# pre-existing priority line there and insert priority=1 after the header.
	awk '
		/^\[/ {
			insec = ($0 ~ /[hH]ummingbird/)
			print
			if (insec) print "priority=1"
			next
		}
		insec && /^[[:space:]]*priority[[:space:]]*=/ { next }
		{ print }
	' "$f" > "$f.tmp" && mv "$f.tmp" "$f" || rm -f "$f.tmp"
done

# Also exclude globally so nothing can swap out hummingbird-release.
if [[ -f /etc/dnf/dnf.conf ]] && ! grep -q '^excludepkgs=' /etc/dnf/dnf.conf; then
	if grep -q '^\[main\]' /etc/dnf/dnf.conf; then
		sed -i "0,/^\[main\]/s//[main]\nexcludepkgs=$release_excludes/" /etc/dnf/dnf.conf
	else
		printf '[main]\nexcludepkgs=%s\n' "$release_excludes" >> /etc/dnf/dnf.conf
	fi
fi

dnf -y makecache || true

# --- dnf plugins (needed for `dnf copr`) ---------------------------------
printf '\e[1;32m-->\e[0m\e[1m Installing dnf-plugins-core\e[0m\n'
dnf -y install --skip-unavailable dnf-plugins-core || true

# --- RPM Fusion (free + nonfree) -----------------------------------------
# Install the release packages with rpm --nodeps: they only drop repo files and
# GPG keys, but declare a hard `system-release(NN)` requirement that, on this
# base, is only satisfiable by the conflicting Fedora release packages. rpm can
# fetch the noarch RPMs directly over https.
printf '\e[1;32m-->\e[0m\e[1m Enabling RPM Fusion (free + nonfree) for %s\e[0m\n' "$releasever"
if rpm -Uvh --nodeps --replacepkgs --nosignature \
	"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${releasever}.noarch.rpm" \
	"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${releasever}.noarch.rpm" ; then
	printf '\e[1;32m-->\e[0m\e[1m RPM Fusion enabled\e[0m\n'
else
	echo "!! RPM Fusion for ${releasever} could not be installed, continuing without it"
fi

# --- COPR repos ----------------------------------------------------------
if [[ -f $variant/copr.list ]]; then
	while read -r repo; do
		repo=${repo%%#*}
		repo=$(echo "$repo" | xargs)
		[[ -z $repo ]] && continue
		printf '\e[1;32m-->\e[0m\e[1m Enabling COPR %s\e[0m\n' "$repo"
		dnf -y copr enable "$repo" || echo "!! failed to enable copr $repo, continuing"
	done < "$variant/copr.list"
fi

# --- Refresh metadata after all repos are configured ---------------------
# NOTE: We intentionally do NOT run a `dnf distro-sync` here. The Hummingbird base
# is a *self-consistent Fedora snapshot* (its installed packages are `.fcNN`/`.hum1`
# builds that all agree on a single glibc/toolchain). Trying to sync that base
# against a DIFFERENT Fedora stream (e.g. rawhide) forces incompatible updates to
# core libraries (libxml2 -> libxkbcommon -> kbd, fuse3-libs -> e2fsprogs,
# containers-common -> podman, ...) and cannot resolve. We instead leave the base
# untouched and only let the overlay repos SUPPLY packages the base lacks, with the
# Hummingbird repos pinned to priority=1 so any shared package keeps its `.hum1`
# build. The main package.list install then adds the extra packages on top.
dnf -y makecache --refresh || true
