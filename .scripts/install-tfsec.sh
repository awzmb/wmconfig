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

TFSEC_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TFSEC_BINARY="tfsec-$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}"
curl -L --output "${TMP_DIR}/${TFSEC_BINARY}" --url "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/${TFSEC_BINARY}"
mv ${TMP_DIR}/${TFSEC_BINARY} ${INSTALL_DIR}/tfsec
chmod +x ${INSTALL_DIR}/tfsec
which tfsec
