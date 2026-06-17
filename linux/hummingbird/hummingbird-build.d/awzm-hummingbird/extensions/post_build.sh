#!/usr/bin/env bash
#
# post_build extension.
#
# arkdep sources this once the build is fully exported, before cleanup. In this
# flow the image has already been built and `bootc container lint` has run as the
# final layer. Use this hook for host-side actions after the image exists, e.g.
# pushing to a registry or signing.
#
# Environment provided by hummingbird-build:
#   $HUMMINGBIRD_IMAGE   full local image reference that was built
#   $HUMMINGBIRD_VARIANT variant name
set -euo pipefail

printf '\e[1;32m-->\e[0m\e[1m Built image: %s\e[0m\n' "${HUMMINGBIRD_IMAGE:-unknown}"

# Example: push to a registry (uncomment and set HUMMINGBIRD_PUSH=registry/repo:tag)
# if [[ -n ${HUMMINGBIRD_PUSH:-} ]]; then
# 	podman tag "$HUMMINGBIRD_IMAGE" "$HUMMINGBIRD_PUSH"
# 	podman push "$HUMMINGBIRD_PUSH"
# fi
