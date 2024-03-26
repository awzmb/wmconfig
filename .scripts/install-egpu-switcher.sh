#!/bin/sh
INSTALL_DIR=${HOME}/.bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  arm|armv6l|armv7l)
    ARCH=arm
    ;;
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

EGPU_SWITCHER_VERSION=$(curl -s https://api.github.com/repos/hertg/egpu-switcher/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
echo $EGPU_SWITCHER_VERSION
EGPU_SWITCHER_BINARY="egpu-switcher-${ARCH}"
echo $EGPU_SWITCHER_BINARY
curl -L --output "${TMP_DIR}/${EGPU_SWITCHER_BINARY}" --url "https://github.com/hertg/egpu-switcher/releases/download/${EGPU_SWITCHER_VERSION}/${EGPU_SWITCHER_BINARY}"
mv ${TMP_DIR}/${EGPU_SWITCHER_BINARY} ${INSTALL_DIR}/egpu-switcher
chmod +x ${INSTALL_DIR}/egpu-switcher
which egpu-switcher
