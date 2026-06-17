#!/usr/bin/env bash
#
# post_bootstrap extension.
#
# arkdep sources this after bootstrapping the base system and applying the
# post_bootstrap overlay, but before installing the package.list packages.
#
# The base Hummingbird image is already a complete system, so there is usually
# nothing to do here. Left as a documented hook; add early system tweaks that
# must happen before package installation.
#
# Runs as root inside the image build. $variant points at the variant config.
set -euo pipefail

variant=${HUMMINGBIRD_VARIANT_DIR:-/run/hummingbird/variant}

printf '\e[1;32m-->\e[0m\e[1m post_bootstrap: refreshing dnf metadata\e[0m\n'
dnf -y makecache || true
