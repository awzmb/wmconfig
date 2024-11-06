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
    ARCH=x86_64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
RAINFROG_VERSION=$(curl -s https://api.github.com/repos/achristmascarl/rainfrog/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
RAINFROG_ARCHIVE="rainfrog-${OS}-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${RAINFROG_ARCHIVE}" --url "https://github.com/achristmascarl/rainfrog/releases/download/v${RAINFROG_VERSION}/rainfrog-v${RAINFROG_VERSION}-${ARCH}-unknown-${OS}-gnu.tar.gz"
tar xf ${TMP_DIR}/${RAINFROG_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/rainfrog ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/rainfrog
