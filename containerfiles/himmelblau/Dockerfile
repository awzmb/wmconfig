# syntax=docker/dockerfile:1

# Stage 1: Build the Rust application
FROM rust:1.97-bookworm@sha256:8fa55b2f3ddf97471ab6a767bfa3f37e6bad0986ba823e75fea57e2a2a5c3073 as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  pkg-config \
  libssl-dev \
  libudev-dev \
  libsss-idmap-dev \
  libunistring-dev \
  libdbus-1-dev \
  libpam0g-dev \
  cmake \
  build-essential \
  clang \
  && rm -rf /var/lib/apt/lists/*

# Clone the repository and build
RUN git clone https://github.com/himmelblau-idm/himmelblau.git .
RUN cargo build --release

# Stage 2: Create the final image
FROM ubuntu:26.10@sha256:a7e5c4bad66bf263642da9a16207ed0fb80668a1f17d2e44c8c5e2cc0ce59346

WORKDIR /app

# Install runtime dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
  libssl3 \
  ca-certificates \
  libsqlite3-0 \
  libdbus-1-3 \
  dbus \
  strace \
  krb5-user \
  sudo \
  && rm -rf /var/lib/apt/lists/*

# Configure Kerberos for Azure / Entra ID.  This tells the system Kerberos
# library (used by browsers and other apps) to use Microsoft's cloud KDC for
# .windows.net and .azure.net realms so that SSO tickets issued by himmelblau
# are accepted by Microsoft Online services.
RUN cat > /etc/krb5.conf <<'EOF'
[libdefaults]
    default_ccache_name = DIR:/tmp/krb5cc_%{uid}
[domain_realm]
    .windows.net = KERBEROS.MICROSOFTONLINE.COM
    .azure.net = KERBEROS.MICROSOFTONLINE.COM
[realms]
    KERBEROS.MICROSOFTONLINE.COM = {
        kdc = https://login.microsoftonline.com/common/kerberos
        kpasswd_server = https://login.microsoftonline.com/common/kerberos
    }
EOF


COPY --from=builder /usr/lib/x86_64-linux-gnu/libunistring.so.2.2.0 /usr/lib/x86_64-linux-gnu/
RUN ln -s /usr/lib/x86_64-linux-gnu/libunistring.so.2.2.0 /usr/lib/x86_64-linux-gnu/libunistring.so.2

# Copy the built binaries from the builder stage
COPY --from=builder /app/target/release/aad-tool /usr/local/bin/
COPY --from=builder /app/target/release/himmelblaud /usr/local/bin/
COPY --from=builder /app/target/release/himmelblaud_tasks /usr/local/bin/
COPY --from=builder /app/target/release/broker /usr/local/bin/
COPY --from=builder /app/target/release/linux-entra-sso /usr/local/bin/

# Copy the docker-entrypoint script and make it executable
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create a non-root user for better security and permissions
# User will have the same UID/GID as a typical default user on Linux (1000)
# This can be overridden at build time with --build-arg USER_ID=xxx --build-arg GROUP_ID=xxx
# NOTE: If running into problems, check your current UID/GID with `id -u` and `id -g`
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=dev
RUN export DEBIAN_FRONTEND=noninteractive && \
  if getent group "$GROUP_ID"; then \
  groupmod -n "$USERNAME" "$(getent group "$GROUP_ID" | cut -d: -f1)"; \
  else \
  groupadd -g "$GROUP_ID" "$USERNAME"; \
  fi && \
  if getent passwd "$USER_ID"; then \
  usermod -l "$USERNAME" -d "/home/$USERNAME" -m "$(id -un "$USER_ID")"; \
  else \
  useradd -u "$USER_ID" -g "$GROUP_ID" -m -s /bin/bash "$USERNAME"; \
  fi

RUN mkdir -p /var/cache/himmelblaud && chmod 700 /var/cache/himmelblaud && chown $USER_ID:$GROUP_ID /var/cache/himmelblaud && \
  mkdir -p /var/lib/himmelblaud && chmod 700 /var/lib/himmelblaud && chown $USER_ID:$GROUP_ID /var/lib/himmelblaud && \
  mkdir -p /var/run/himmelblaud && chmod 700 /var/run/himmelblaud && chown $USER_ID:$GROUP_ID /var/run/himmelblaud && \
  mkdir -p /run/intune && chmod 700 /run/intune && chown $USER_ID:$GROUP_ID /run/intune && \
  mkdir -p /var/cache/himmelblau-policies && chmod 700 /var/cache/himmelblau-policies
RUN mkdir -p /etc/himmelblau && chown root:root /etc/himmelblau
# Note: himmelblau.conf is NOT baked into the image. start.sh writes the
# config from HIMMELBLAU_DOMAIN / HIMMELBLAU_TENANT_ID and mounts the
# host-side config directory over /etc/himmelblau at runtime.

# Allow the container user to run himmelblaud_tasks as root without a password.
# himmelblaud_tasks performs Intune device-enrollment and compliance-reporting
# tasks that require UID 0; all other operations in the container remain
# unprivileged.  The rule is scoped to the exact binary path so no other
# commands gain elevated privileges.
# !use_pty: Ubuntu 24.04 enables "Defaults use_pty" globally, which causes sudo
# to create a pseudo-terminal for the child and relay its I/O through /dev/tty.
# When himmelblaud_tasks runs in the background (& with stdout/stderr redirected
# to a log file), the PTY relay can still write bytes to the controlling terminal
# and corrupt the cursor position of any banner drawn later.  Disabling use_pty
# for this specific command ensures its output goes directly to the redirected
# file descriptor without any PTY relay.
RUN { \
      echo "${USERNAME} ALL=(root) NOPASSWD: SETENV: /usr/local/bin/himmelblaud_tasks"; \
      echo 'Defaults!/usr/local/bin/himmelblaud_tasks !use_pty'; \
    } > /etc/sudoers.d/himmelblaud_tasks \
    && chmod 0440 /etc/sudoers.d/himmelblaud_tasks

# Switch to the new user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Set the entrypoint to the docker-entrypoint script
ENTRYPOINT ["docker-entrypoint.sh"]
