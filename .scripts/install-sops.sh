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

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
SOPS_BINARY="sops-v${SOPS_VERSION}.${OS}.${ARCH}"
curl -L --output "${TMP_DIR}/${SOPS_BINARY}" --url "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/${SOPS_BINARY}"
mv ${TMP_DIR}/${SOPS_BINARY} ${INSTALL_DIR}/sops
chmod +x ${INSTALL_DIR}/sops
