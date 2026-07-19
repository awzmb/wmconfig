FROM docker.io/golang:1.26.5-trixie@sha256:117e07f49461abb984fc8aef661432461ff43d06faa22c3b73af6a49ce325cb9 AS build

RUN git clone https://github.com/kubernetes/kompose.git /go/src/kompose

WORKDIR /go/src/kompose

RUN go clean --testcache && go test

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/kompose main.go

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

ENTRYPOINT ["/go/bin/kompose"]
