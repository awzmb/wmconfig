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
    ARCH=x86_64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

GLOW_VERSION=$(curl -s https://api.github.com/repos/charmbracelet/glow/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
GLOW_ARCHIVE="glow_$(uname -s)_${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${GLOW_ARCHIVE}" --url "https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/${GLOW_ARCHIVE}"
tar xfz ${TMP_DIR}/${GLOW_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/glow ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/glow
which glow
