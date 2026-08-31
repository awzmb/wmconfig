FROM cgr.dev/chainguard/wolfi-base:latest@sha256:19f7a7b40a11c435311e3784bd134c6b6f19677462440da48f96d5c84eefd669 AS build

RUN apk add --no-cache ca-certificates curl unzip

ARG PLATFORM_TOOLS_URL=https://dl.google.com/android/repository/platform-tools-latest-linux.zip
ARG CMDLINE_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip

RUN mkdir -p /opt/android-sdk && cd /opt/android-sdk \
  && curl -fsSL -o pt.zip "${PLATFORM_TOOLS_URL}" && unzip -q pt.zip && rm pt.zip \
  && mkdir -p cmdline-tools && cd cmdline-tools \
  && curl -fsSL -o clt.zip "${CMDLINE_TOOLS_URL}" && unzip -q clt.zip && rm clt.zip \
  && mv cmdline-tools latest

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:19f7a7b40a11c435311e3784bd134c6b6f19677462440da48f96d5c84eefd669

RUN apk add --no-cache \
  bash \
  ca-certificates \
  curl \
  glibc \
  libusb \
  openjdk-21-default-jdk \
  unzip \
  zip

COPY --from=build /opt/android-sdk /opt/android-sdk

ENV ANDROID_HOME=/opt/android-sdk \
  ANDROID_SDK_ROOT=/opt/android-sdk \
  PATH=/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin

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
  addgroup -g "$GROUP_ID" -S "$USERNAME" >/dev/null 2>&1 || true && \
  \
  # Check if a user with the target UID already exists but has the wrong name.
  if grep -q ":x:${USER_ID}:" /etc/passwd; then \
  EXISTING_USER_NAME=$(grep ":x:${USER_ID}:" /etc/passwd | cut -d: -f1); \
  if [ "$EXISTING_USER_NAME" != "$USERNAME" ]; then \
  deluser "$EXISTING_USER_NAME"; \
  fi; \
  fi && \
  adduser -D -S -h "/home/$USERNAME" -s /bin/bash -G "$USERNAME" -u "$USER_ID" "$USERNAME" >/dev/null 2>&1 || true

# ponytail: SDK owned by the user so sdkmanager can install packages in place
RUN chown -R "${USER_ID}:${GROUP_ID}" /opt/android-sdk

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ponytail: no ENTRYPOINT so `podman run <img> adb devices` works, bare run gives a shell
CMD ["/bin/bash"]
