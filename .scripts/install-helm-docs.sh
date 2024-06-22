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
    ARCH=x86_64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

HELM_DOCS_VERSION=$(curl -s https://api.github.com/repos/norwoodj/helm-docs/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
HELM_DOCS_ARCHIVE="helm-docs_${HELM_DOCS_VERSION}_$(uname -s)_${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${HELM_DOCS_ARCHIVE}" --url "https://github.com/norwoodj/helm-docs/releases/download/v${HELM_DOCS_VERSION}/${HELM_DOCS_ARCHIVE}"
tar xfz ${TMP_DIR}/${HELM_DOCS_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/helm-docs ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/helm-docs
which helm-docs
