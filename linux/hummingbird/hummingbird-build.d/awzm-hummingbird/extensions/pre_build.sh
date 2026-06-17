#!/usr/bin/env bash
#
# pre_build extension.
#
# arkdep runs pre_build.sh after the Btrfs subvolumes are created but before
# bootstrap. In the bootc/Containerfile flow there is no separate bootstrap (the
# base image already exists), so we use this hook to wire up the extra package
# sources that the ported package.list depends on: RPM Fusion (free + nonfree)
# and any COPR repos listed in copr.list.
#
# This is the Fedora analogue of awzmlinux/extensions/post_bootstrap.sh, which
# enabled the Chaotic-AUR on Arch.
#
# Runs as root inside the image build. $variant points at the variant config.
set -euo pipefail

variant=${HUMMINGBIRD_VARIANT_DIR:-/run/hummingbird/variant}
relver=$(rpm -E %fedora 2>/dev/null || echo rawhide)

printf '\e[1;32m-->\e[0m\e[1m Enabling dnf plugins core\e[0m\n'
dnf -y install dnf-plugins-core || true

printf '\e[1;32m-->\e[0m\e[1m Enabling RPM Fusion (free + nonfree)\e[0m\n'
dnf -y install \
	"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${relver}.noarch.rpm" \
	"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${relver}.noarch.rpm" \
	|| echo '!! RPM Fusion not available for this release, continuing without it'

if [[ -f $variant/copr.list ]]; then
	while read -r repo; do
		repo=${repo%%#*}
		repo=$(echo "$repo" | xargs)
		[[ -z $repo ]] && continue
		printf '\e[1;32m-->\e[0m\e[1m Enabling COPR %s\e[0m\n' "$repo"
		dnf -y copr enable "$repo" || echo "!! failed to enable copr $repo, continuing"
	done < "$variant/copr.list"
fi
