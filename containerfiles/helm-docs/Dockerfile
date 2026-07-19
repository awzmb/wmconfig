FROM cgr.dev/chainguard/wolfi-base:latest@sha256:02dab76bd852a70556b5b2002195c8a5fdab77d323c433bf6642aab080489795

RUN apk add --no-cache \
  helm-docs

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

ENTRYPOINT ["/usr/bin/helm-docs"]
