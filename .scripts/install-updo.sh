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

UPDO_VERSION=$(curl -s https://api.github.com/repos/Owloops/updo/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
UPDO_ARCHIVE="updo_$(uname -s)_${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${UPDO_ARCHIVE}" --url "https://github.com/Owloops/updo/releases/download/v${UPDO_VERSION}/${UPDO_ARCHIVE}"
tar xf ${TMP_DIR}/${UPDO_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/updo ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/updo
