# pasta (passt) - rootless network backend for nested podman.# Wolfi has no passt package and podman >= 6.0 dropped slirp4netns support, so
# build it from upstream.
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:c08875f557c44f2e376d40ab68a6674234a8eeef06a0d10fbe9d2db40bcdb531 AS pasta-build

# Upstream lives on passt.top, not GitHub, so Renovate tracks it via git-tags
# (`git ls-remote`). Tags are dates plus the short commit hash, hence the regex
# versioning.
ARG PASST_VERSION="2026_07_28.f8df3f1"

# coreutils: the seccomp profile generator (seccomp.sh) needs `fmt`, which
# busybox does not provide.
# posix-libc-utils: the Makefile bakes the page size in via
# `-DPAGE_SIZE=$(shell getconf PAGE_SIZE)`. Without getconf that expands to
# nothing and every use of PAGE_SIZE fails to compile.
RUN apk add --no-cache build-base coreutils posix-libc-utils linux-headers git

# The tag name carries the commit it points at; git verifies object hashes on
# clone, so matching the two is the integrity check.
RUN set -eux; \
  git clone --depth 1 --branch "${PASST_VERSION}" https://passt.top/passt /tmp/passt; \
  cd /tmp/passt; \
  case "$(git rev-parse HEAD)" in "${PASST_VERSION##*.}"*) ;; \
  *) echo "passt ${PASST_VERSION} does not point at commit ${PASST_VERSION##*.}" >&2; exit 1 ;; esac; \
  make -j"$(nproc)" VERSION="${PASST_VERSION}" passt passt.avx2 pasta pasta.avx2; \
  mkdir -p /out; \
  install -m755 passt passt.avx2 /out/; \
  cp -d pasta pasta.avx2 /out/

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:c08875f557c44f2e376d40ab68a6674234a8eeef06a0d10fbe9d2db40bcdb531 AS build

RUN apk add --no-cache \
  ca-certificates \
  gnutar \
  curl

ADD install-copilot.sh /tmp/install-copilot.sh

RUN chmod +x /tmp/install-copilot.sh && /tmp/install-copilot.sh

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:c08875f557c44f2e376d40ab68a6674234a8eeef06a0d10fbe9d2db40bcdb531

RUN apk add --no-cache \
  ca-certificates \
  curl \
  gh \
  git \
  helm \
  helm-docs \
  gcc \
  go \
  make \
  glibc \
  tzdata \
  rust \
  rust-analyzer \
  bash \
  nodejs \
  yarn \
  pnpm \
  shadow \
  opentofu \
  terragrunt \
  kustomize \
  cmake \
  openssl \
  jq \
  yq \
  uv \
  python3 \
  golangci-lint

# Rootless nested containers: podman plus the helpers it shells out to.
# fuse-overlayfs is the only storage driver that works unprivileged inside
# another container; netavark/aardvark-dns handle bridge networks and their
# DNS; shadow-subids provides newuidmap/newgidmap for the user namespace.
RUN apk add --no-cache \
  podman \
  crun \
  conmon \
  fuse-overlayfs \
  fuse3 \
  netavark \
  aardvark-dns \
  shadow-subids

COPY --from=build /usr/bin/copilot /usr/bin/copilot

# pasta binaries built in the stage above. passt prefers the AVX2 variant at
# runtime and falls back to the baseline build, so both ship; pasta/pasta.avx2
# are symlinks (argv[0] selects the mode).
COPY --from=pasta-build /out/ /usr/bin/

# Create a non-root user for better security and permissions
# User will have the same UID/GID as a typical default user on Linux (1000)
# This can be overridden at build time with --build-arg USER_ID=xxx --build-arg GROUP_ID=xxx
# NOTE: If running into problems, check your current UID/GID with `id -u` and `id -g`
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=dev
RUN \
  # --- GROUP SETUP ---
  # Check if a group with the target GID already exists but has the wrong name.
  # If so, we must delete it first to "take over" the GID.
  if grep -q ":x:${GROUP_ID}:" /etc/group; then \
  EXISTING_GROUP_NAME=$(grep ":x:${GROUP_ID}:" /etc/group | cut -d: -f1); \
  if [ "$EXISTING_GROUP_NAME" != "$USERNAME" ]; then \
  delgroup "$EXISTING_GROUP_NAME"; \
  fi; \
  fi && \
  # Ensure our desired group exists. `addgroup` will fail if the GID is taken,
  # which we handled above. It will also fail if the group name already exists,
  # which is fine. The `|| true` makes this command idempotent.
  addgroup -g "$GROUP_ID" -S "$USERNAME" >/dev/null 2>&1 || true && \
  \
  # --- USER SETUP ---
  # Check if a user with the target UID already exists but has the wrong name.
  # If so, we must delete it first to "take over" the UID.
  if grep -q ":x:${USER_ID}:" /etc/passwd; then \
  EXISTING_USER_NAME=$(grep ":x:${USER_ID}:" /etc/passwd | cut -d: -f1); \
  if [ "$EXISTING_USER_NAME" != "$USERNAME" ]; then \
  deluser "$EXISTING_USER_NAME"; \
  fi; \
  fi && \
  # Ensure our desired user exists.
  # -D: Don't assign a password
  # -S: Create a system user
  # -h: Set home directory
  # -s: Set shell
  # -G: Add to group (primary group)
  # -u: Set UID
  adduser -D -S -h "/home/$USERNAME" -s /bin/bash -G "$USERNAME" -u "$USER_ID" "$USERNAME" >/dev/null 2>&1 || true

# --- ROOTLESS PODMAN: USER NAMESPACE ---
# Subordinate UID/GID range for the user. Must stay within 0-65535 (the outer
# rootless-container user namespace limit) and must NOT include the user's own
# UID - Podman rejects subuid ranges that overlap it. Starting right above
# USER_ID and running to 65534 gives nested containers the largest usable range.
RUN set -eu; \
  SUB_START=$((USER_ID + 1)); \
  SUB_COUNT=$((65535 - SUB_START)); \
  echo "${USERNAME}:${SUB_START}:${SUB_COUNT}" > /etc/subuid; \
  echo "${USERNAME}:${SUB_START}:${SUB_COUNT}" > /etc/subgid; \
  # newuidmap/newgidmap must be setuid-root so crun can invoke them as the user.
  # Wolfi/Chainguard strips setuid bits at install time; restore them here.
  chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap

# --- ROOTLESS PODMAN: STORAGE DIRS ---
# Baked into the image layer and owned by the user, so nothing has to be created
# at container start. runroot must NOT live under /run: for bridge networks
# rootless podman runs netavark/aardvark-dns in a private mount namespace with an
# empty dir bind-mounted over /run, which would hide it ("failed to create
# aardvark-dns directory").
# tmp_dir: Podman appends libpod/tmp/ for pause.pid and other runtime state.
RUN mkdir -p \
  /var/lib/containers/storage \
  /var/lib/containers/tmp/containers \
  /var/lib/containers/tmp/libpod/tmp && \
  chown -R "${USER_ID}:${GROUP_ID}" /var/lib/containers

# fuse-overlayfs is what makes overlay storage work inside another container.
# ignore_chown_errors: if the outer namespace maps only a single UID, lchown for
# any other UID would fail; ignoring is the standard rootless-in-container
# workaround.
RUN mkdir -p /etc/containers && tee /etc/containers/storage.conf <<EOF
[storage]
driver = "overlay"
runroot = "/var/lib/containers/tmp/containers"
graphroot = "/var/lib/containers/storage"
[storage.options]
ignore_chown_errors = "true"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

# pasta for rootless networking: works without CNI or host network access, and
# is the only supported rootless network backend as of podman 6.0 (slirp4netns
# was dropped).
RUN tee /etc/containers/containers.conf <<EOF
[network]
default_rootless_network_cmd = "pasta"

[engine]
# Redirect Podman's tmp dir away from /run/user/<uid>/libpod/tmp, which lives on
# a tmpfs and is empty at container start.
tmp_dir = "/var/lib/containers/tmp"
EOF

# Search Docker Hub for unqualified image names (e.g. "ubuntu" -> "docker.io/library/ubuntu").
RUN tee /etc/containers/registries.conf <<EOF
unqualified-search-registries = ["docker.io"]
EOF

# XDG_RUNTIME_DIR: rootless Podman uses this for socket/pid files and it must
# exist at container start. /run/user/<uid> lives on a tmpfs and is empty, so
# point at the directory baked in above.
ENV XDG_RUNTIME_DIR=/var/lib/containers/tmp

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENTRYPOINT ["copilot"]
