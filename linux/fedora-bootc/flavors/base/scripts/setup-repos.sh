#!/usr/bin/env bash
#
# setup-repos.sh — add the extra package sources package.list depends on, run by
# the Containerfile before the package install.
#
# The base is a STANDARD Fedora bootc image (quay.io/fedora/fedora-bootc), which
# already ships the Fedora repos and GPG keys. So — unlike the old distroless
# Fedora base — there is nothing to do about the base Fedora repos, release
# detection, GPG keys or repo priorities. We only add RPM Fusion (the free +
# nonfree extras package.list depends on).
#
# Runs as root inside the image build.
set -euo pipefail

releasever=$(rpm -E %fedora)

printf '\e[1;32m-->\e[0m\e[1m Building on Fedora %s\e[0m\n' "$releasever"

# --- RPM Fusion (free + nonfree) -----------------------------------------
# On a standard Fedora base fedora-release is present, so the release RPMs
# install normally (no rpm --nodeps hackery needed).
printf '\e[1;32m-->\e[0m\e[1m Enabling RPM Fusion (free + nonfree) for %s\e[0m\n' "$releasever"
dnf -y install \
	"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${releasever}.noarch.rpm" \
	"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${releasever}.noarch.rpm" \
	|| echo "!! RPM Fusion for ${releasever} could not be installed, continuing without it"
# ponytail: RPM Fusion may not have published a release RPM for a brand-new
# rawhide bump yet; the build continues without it (RPM Fusion packages then get
# dropped by --skip-unavailable). Re-run once RPM Fusion catches up.

# --- Tailscale (mesh VPN) ------------------------------------------------
# Tailscale ships its own dnf repo; drop it in so package.list's `tailscale`
# resolves. repo_gpgcheck verifies the repo metadata; the packages themselves
# are validated the same way (gpgcheck=0 upstream, repo signed).
printf '\e[1;32m-->\e[0m\e[1m Enabling the Tailscale stable repo\e[0m\n'
cat > /etc/yum.repos.d/tailscale.repo <<'EOF'
[tailscale-stable]
name=Tailscale stable
baseurl=https://pkgs.tailscale.com/stable/fedora/$basearch
enabled=1
type=rpm
repo_gpgcheck=1
gpgcheck=0
gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg
EOF

# --- Refresh metadata after all repos are configured ---------------------
dnf -y makecache --refresh || true
