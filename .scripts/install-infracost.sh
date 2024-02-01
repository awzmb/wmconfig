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

INFRACOST_VERSION=$(curl -s https://api.github.com/repos/infracost/infracost/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
INFRACOST_ARCHIVE="infracost-$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${INFRACOST_ARCHIVE}" --url "https://github.com/infracost/infracost/releases/download/v${INFRACOST_VERSION}/${INFRACOST_ARCHIVE}"
tar xf ${TMP_DIR}/${INFRACOST_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/infracost-$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH} ${INSTALL_DIR}/infracost
chmod +x ${INSTALL_DIR}/infracost
which infracost
