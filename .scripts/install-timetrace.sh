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
    exit 2
esac

mkdir -p ${INSTALL_DIR}

TIMETRACE_VERSION=$(curl -s https://api.github.com/repos/dominikbraun/timetrace/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TIMETRACE_ARCHIVE="timetrace-$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${TIMETRACE_ARCHIVE}" --url "https://github.com/dominikbraun/timetrace/releases/download/v${TIMETRACE_VERSION}/${TIMETRACE_ARCHIVE}"
tar xf ${TMP_DIR}/${TIMETRACE_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/timetrace ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/timetrace
which timetrace
