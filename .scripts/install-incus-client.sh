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
  amd64|x86_64)
    ARCH=x86_64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

INCUS_CLIENT_VERSION=$(curl -s https://api.github.com/repos/lxc/incus/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
curl -L --output "${INSTALL_DIR}/incus" --url "https://github.com/lxc/incus/releases/download/v${INCUS_CLIENT_VERSION}/bin.linux.incus.${ARCH}"
chmod +x ${INSTALL_DIR}/incus
echo $(which incus)
