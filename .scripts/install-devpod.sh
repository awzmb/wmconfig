#!/bin/sh
INSTALL_DIR=${HOME}/.bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  arm64|aarch64|armv8l)
    ARCH=arm64
    ;;
  amd64|x86_64)
    ARCH=amd64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
DEVPOD_VERSION=$(curl -s https://api.github.com/repos/loft-sh/devpod/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
DEVPOD_BINARY="devpod-${OS}-${ARCH}"
curl -L --output "${TMP_DIR}/${DEVPOD_BINARY}" --url "https://github.com/loft-sh/devpod/releases/download/v${DEVPOD_VERSION}/${DEVPOD_BINARY}"
mv ${TMP_DIR}/${DEVPOD_BINARY} ${INSTALL_DIR}/devpod
chmod +x ${INSTALL_DIR}/devpod
