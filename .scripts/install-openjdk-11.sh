#!/bin/sh
INSTALL_DIR=${HOME}/.jdk
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  amd64|x86_64)
    ARCH=x64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

OPENJDK_ARCHIVE="openjdk-11_$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}_bin.tar.gz"
curl -L --output "${TMP_DIR}/${OPENJDK_ARCHIVE}" --url "https://download.java.net/java/ga/jdk11/${OPENJDK_ARCHIVE}"
tar xf ${TMP_DIR}/${OPENJDK_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/jdk-11 ${INSTALL_DIR}/openjdk-11
