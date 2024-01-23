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
HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
HELM_ARCHIVE="helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${HELM_ARCHIVE}" --url "https://get.helm.sh/${HELM_ARCHIVE}"
tar xfz ${TMP_DIR}/${HELM_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/${OS}-${ARCH}/helm ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/helm
