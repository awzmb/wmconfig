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
ACTION_VALIDATOR_VERSION=$(curl -s https://api.github.com/repos/mpalmer/action-validator/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
ACTION_VALIDATOR_BINARY="action-validator_${OS}_${ARCH}"
curl -L --output "${TMP_DIR}/${ACTION_VALIDATOR_BINARY}" --url "https://github.com/mpalmer/action-validator/releases/download/v${ACTION_VALIDATOR_VERSION}/${ACTION_VALIDATOR_BINARY}"
mv ${TMP_DIR}/${ACTION_VALIDATOR_BINARY} ${INSTALL_DIR}/action-validator
chmod +x ${INSTALL_DIR}/action-validator
