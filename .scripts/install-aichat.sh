#!/bin/sh
INSTALL_DIR=${HOME}/.bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  arm64|aarch64|armv8l)
    ARCH=aarch64
    ;;
  arm)
    ARCH=arm
    ;;
  armv7)
    ARCH=armv7
    ;;
  i686)
    ARCH=i686
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

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
AICHAT_VERSION=$(curl -s https://api.github.com/repos/sigoden/aichat/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
AICHAT_ARCHIVE="aichat-v${AICHAT_VERSION}-${ARCH}-unknown-${OS}-musl.tar.gz"
curl -L --output "${TMP_DIR}/${AICHAT_ARCHIVE}" --url "https://github.com/sigoden/aichat/releases/download/v${AICHAT_VERSION}/${AICHAT_ARCHIVE}"
tar xf ${TMP_DIR}/${AICHAT_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/aichat ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/aichat
which aichat
