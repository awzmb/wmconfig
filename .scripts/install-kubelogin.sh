#!/bin/sh
INSTALL_DIR=${HOME}/.bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
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
KUBELOGIN_VERSION=$(curl -s https://api.github.com/repos/int128/kubelogin/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
KUBELOGIN_ARCHIVE="kubelogin_${OS}_${ARCH}.zip"
curl -L --output "${TMP_DIR}/${KUBELOGIN_ARCHIVE}" --url "https://github.com/int128/kubelogin/releases/download/v${KUBELOGIN_VERSION}/${KUBELOGIN_ARCHIVE}"
unzip ${TMP_DIR}/${KUBELOGIN_ARCHIVE} -d ${TMP_DIR}
mv ${TMP_DIR}/kubelogin ${INSTALL_DIR}/kubectl-oidc_login
chmod +x ${INSTALL_DIR}/kubectl-oidc_login
which kubectl-oidc_login
