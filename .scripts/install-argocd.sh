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
curl -sSL -o ${INSTALL_DIR}/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-${OS}-${ARCH}
chmod +x ${INSTALL_DIR}/argocd
which argocd
