#!/bin/sh
set -x
INSTALL_DIR=/usr/bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then ARCH=$(uname -m)
fi
case ${ARCH} in
  arm|armv6l|armv7l)
    ARCH=arm
    ;;
  arm64|aarch64|armv8l)
    ARCH=arm64
    ;;
  amd64|x86_64)
    ARCH=x64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
COPILOT_VERSION=$(curl -s https://api.github.com/repos/github/copilot-cli/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
COPILOT_ARCHIVE="copilot-${OS}-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${COPILOT_ARCHIVE}" --url "https://github.com/github/copilot-cli/releases/download/v${COPILOT_VERSION}/${COPILOT_ARCHIVE}"
tar xf ${TMP_DIR}/${COPILOT_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/copilot ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/copilot
