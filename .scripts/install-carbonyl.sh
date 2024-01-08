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

CARBONYL_VERSION=$(curl -s https://api.github.com/repos/fathyb/carbonyl/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
CARBONYL_ARCHIVE="carbonyl.$(uname -s)-${ARCH}.zip"
curl -L --output "${TMP_DIR}/${CARBONYL_ARCHIVE}" --url "https://github.com/fathyb/carbonyl/releases/download/v${CARBONYL_VERSION}/${CARBONYL_ARCHIVE}"
unzip ${TMP_DIR}/${CARBONYL_ARCHIVE} -d ${TMP_DIR}
mv ${TMP_DIR}/carbonyl ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/carbonyl
