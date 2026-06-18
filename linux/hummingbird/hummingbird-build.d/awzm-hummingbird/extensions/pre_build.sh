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

# Hummingbird is a rolling, rawhide-based distribution, so we ALWAYS build
# against Fedora rawhide. There is intentionally no option to target a numbered
# release.
releasever=rawhide
basearch=$(rpm -E %_arch 2>/dev/null || echo x86_64)

# Never let Fedora's release/identity packages replace hummingbird-release.
# (Belt and braces: excluded per-repo below AND globally.)
release_excludes='generic-release,fedora-release,fedora-release-*,fedora-repos,fedora-repos-*,fedora-identity-*'

# Make dnf resolve $releasever consistently for the rest of the build (COPR,
# RPM Fusion repo files all use $releasever).
mkdir -p /etc/dnf/vars
echo "$releasever" > /etc/dnf/vars/releasever

# --- Add the standard Fedora repositories --------------------------------
# The Hummingbird base is "distroless" and only ships its own curated repo, so we
# add the regular Fedora rawhide repo. Helper that (re)writes the repo file; the
# GPG key is filled in once we know the numeric release rawhide currently maps to.
repo_file=/etc/yum.repos.d/fedora-hummingbird-overlay.repo
write_fedora_repo() {  # $1 = gpgcheck (0/1), $2 = gpgkey value (optional)
	local gc=$1 key=${2:-}
	{
		echo '[fedora-hb]'
		echo 'name=Fedora rawhide - $basearch'
		echo 'metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-rawhide&arch=$basearch'
		echo 'enabled=1'
		echo 'countme=0'
		echo "gpgcheck=$gc"
		[[ -n $key ]] && echo "gpgkey=$key"
		echo "excludepkgs=$release_excludes"
		echo 'skip_if_unavailable=False'
	} > "$repo_file"
}

# Bootstrap the repo with gpgcheck disabled just long enough to read its metadata
# (repository metadata is not OpenPGP-checked by default, package payloads are).
write_fedora_repo 0
printf '\e[1;32m-->\e[0m\e[1m Refreshing repositories\e[0m\n'
dnf -y makecache || true

# Resolve which Fedora version rawhide currently is, so we import the matching
# numbered GPG key. This is detected dynamically so the build survives the rawhide
# version bump (e.g. when 45 is released and rawhide becomes 46). The key MUST
# match the packages served by the rawhide repo (which may be newer than the
# packages already installed in the base), so we query the repo itself first.
detect_rawhide_relver() {
	local v
	# 1. Release of a core package *in the rawhide repo* (authoritative: it is
	#    exactly what the to-be-installed packages are signed against). Try the
	#    dnf5 (--repo) and dnf4 (--repoid) spellings, falling back to an
	#    unrestricted query (the highest fcNN across repos is the rawhide one).
	for sel in "--repo=fedora-hb" "--repoid=fedora-hb" ""; do
		v=$(dnf -q repoquery $sel --qf '%{release}\n' \
			bash filesystem coreutils glibc setup 2>/dev/null \
			| grep -oP 'fc\K[0-9]+' | sort -n | tail -n1 || true)
		[[ $v =~ ^[0-9]+$ ]] && { echo "$v"; return; }
	done
	# 2. The rpm %fedora macro.
	v=$(rpm -E %fedora 2>/dev/null || true)
	[[ $v =~ ^[0-9]+$ ]] && { echo "$v"; return; }
	# 3. Network fallback: the highest-numbered key in the rawhide dist-git branch.
	v=$(curl -fsSL "https://src.fedoraproject.org/rpms/fedora-repos/tree/rawhide/f" 2>/dev/null \
		| grep -oE 'RPM-GPG-KEY-fedora-[0-9]+-primary' | grep -oE '[0-9]+' | sort -n | tail -n1 || true)
	[[ $v =~ ^[0-9]+$ ]] && { echo "$v"; return; }
	return 1
}

key_relver=$(detect_rawhide_relver || true)
printf '\e[1;32m-->\e[0m\e[1m Targeting Fedora rawhide (currently Fedora %s)\e[0m\n' \
	"${key_relver:-unknown}"

# Resolve the GPG key for that release: prefer an on-disk key, else fetch the
# official numbered key over https (dnf imports it automatically). Keep
# gpgcheck=1 so package payloads stay verified.
gpgcheck=1
gpgkey=""
if [[ $key_relver =~ ^[0-9]+$ ]]; then
	if [[ -e "/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${key_relver}-${basearch}" ]]; then
		gpgkey="file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${key_relver}-${basearch}"
	else
		alt=$(ls /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${key_relver}-* 2>/dev/null | head -n1 || true)
		if [[ -n $alt ]]; then
			gpgkey="file://$alt"
		else
			gpgkey="https://src.fedoraproject.org/rpms/fedora-repos/raw/rawhide/f/RPM-GPG-KEY-fedora-${key_relver}-primary"
			echo "-> Fedora ${key_relver} GPG key not on disk; importing from ${gpgkey}"
		fi
	fi
else
	echo "!! could not determine the rawhide release number; disabling gpgcheck as a last resort"
	gpgcheck=0
fi

write_fedora_repo "$gpgcheck" "$gpgkey"

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
if rpm -Uvh --nodeps --replacepkgs \
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
