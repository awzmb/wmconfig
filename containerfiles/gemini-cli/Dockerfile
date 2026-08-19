FROM docker.io/node:26.7.0-alpine3.23@sha256:ce3cc39fe3b8b2602d3b1c4d63d301e46b48c550ecb627869853ddcdda418b63 AS build

WORKDIR /app

# Install gemini-cli using pnpm into /app/node_modules.
RUN apk add --no-cache pnpm \
  && pnpm init \
  && pnpm add @google/gemini-cli@0.50.0

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:a26d8c1c162245273d891d7140e2828d3acbb68051e7bb74ed6f96e59c7392c3

RUN apk add --no-cache \
  nodejs \
  bash \
  coreutils

# Copy the installed node_modules (gemini-cli + deps, including the
# node_modules/.bin/gemini launcher) from the builder stage.
COPY --from=build /app/node_modules ./node_modules

# npm already ships the launcher at node_modules/.bin/gemini.
# Expose it as `gemini-cli` on PATH and use it as the entrypoint.
RUN mkdir -p /usr/local/bin \
  && ln -s /node_modules/.bin/gemini /usr/local/bin/gemini-cli

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=dev
RUN \
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

USER ${USERNAME}
WORKDIR /home/${USERNAME}

CMD ["gemini-cli"]
