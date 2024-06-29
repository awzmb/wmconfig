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
TERRAFORMER_VERSION=$(curl -s https://api.github.com/repos/GoogleCloudPlatform/terraformer/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TERRAFORMER_BINARY="terraformer-google-${OS}-${ARCH}"
curl -L --output "${TMP_DIR}/${TERRAFORMER_BINARY}" --url "https://github.com/GoogleCloudPlatform/terraformer/releases/download/${TERRAFORMER_VERSION}/${TERRAFORMER_BINARY}"
mv ${TMP_DIR}/${TERRAFORMER_BINARY} ${INSTALL_DIR}/terraformer-google
chmod +x ${INSTALL_DIR}/terraformer-google
which terraformer-google
