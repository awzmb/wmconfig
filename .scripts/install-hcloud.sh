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

HCLOUD_VERSION=$(curl -s https://api.github.com/repos/hetznercloud/cli/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
HCLOUD_ARCHIVE="hcloud-$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${HCLOUD_ARCHIVE}" --url "https://github.com/hetznercloud/cli/releases/download/v${HCLOUD_VERSION}/${HCLOUD_ARCHIVE}"
tar xf ${TMP_DIR}/${HCLOUD_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/hcloud ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/hcloud
