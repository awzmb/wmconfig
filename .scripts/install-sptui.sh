#!/bin/sh
INSTALL_DIR=${HOME}/.bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  arm|arm64|aarch64|armv8l)
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

SPTUI_VERSION=$(curl -s https://api.github.com/repos/szktkfm/sptui/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
SPTUI_ARCHIVE="sptui_$(uname -s)_${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${SPTUI_ARCHIVE}" --url "https://github.com/szktkfm/sptui/releases/download/v${SPTUI_VERSION}/${SPTUI_ARCHIVE}"
tar xfz ${TMP_DIR}/${SPTUI_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/sptui ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/sptui
which sptui
