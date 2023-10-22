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

TOFU_VERSION=$(curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TOFU_ARCHIVE="tofu_${TOFU_VERSION}_$(uname -s | tr '[:upper:]' '[:lower:]')_${ARCH}.zip"
curl -L --output "${TMP_DIR}/${TOFU_ARCHIVE}" --url "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/${TOFU_ARCHIVE}"
unzip ${TMP_DIR}/${TOFU_ARCHIVE} -d ${TMP_DIR}
mv ${TMP_DIR}/tofu ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/tofu
