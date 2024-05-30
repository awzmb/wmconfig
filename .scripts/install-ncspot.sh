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

NCSPOT_VERSION=$(curl -s https://api.github.com/repos/hrkfdn/ncspot/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
NCSPOT_ARCHIVE="ncspot-v${NCSPOT_VERSION}-$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${NCSPOT_ARCHIVE}" --url "https://github.com/hrkfdn/ncspot/releases/download/v${NCSPOT_VERSION}/${NCSPOT_ARCHIVE}"
tar xfz ${TMP_DIR}/${NCSPOT_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/ncspot ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/ncspot
echo $(which ncspot)
