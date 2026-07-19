FROM docker.io/hashicorp/terraform:1.15.8@sha256:7ae513256f7ce67879e218ae8593d6fbe216ec9e123abe6c94e4e10704857963 AS terraform
FROM docker.io/cytopia/terraform-docs:0.20.0@sha256:c1b894923ac72e64780d9464245090c98cb3800e9c98c36181d32d9c49d3a30c AS terraform-docs

FROM python:3.14.0rc3-slim-trixie@sha256:e1bb3adc44d158b8b37d647dbfa5864b74f387552c5f12abe9cc95ae773b7c69 AS build

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN uv venv "$VIRTUAL_ENV"

RUN uv pip install --allow-insecure-host pypi.org --allow-insecure-host files.pythonhosted.org pre-commit

RUN apt-get update \
  && apt-get install -y --no-install-recommends git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=terraform-docs /usr/local/bin/terraform-docs /usr/local/bin/terraform-docs

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

WORKDIR /app

ENTRYPOINT ["pre-commit"]
