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

DEVPOD_APPIMAGE="devpod-$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}"
curl -L --output "${TMP_DIR}/${DEVPOD_APPIMAGE}" --url "https://github.com/loft-sh/devpod/releases/latest/download/${DEVPOD_APPIMAGE}"
chmod 755 "${TMP_DIR}/${DEVPOD_APPIMAGE}"
sudo mv "${TMP_DIR}/${DEVPOD_APPIMAGE}" /usr/local/bin/devpod
which devpod
