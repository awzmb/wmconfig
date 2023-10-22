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

K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
K9S_ARCHIVE="k9s_$(uname -s)_${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${K9S_ARCHIVE}" --url "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/${K9S_ARCHIVE}"
tar xf ${TMP_DIR}/${K9S_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/k9s ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/k9s
