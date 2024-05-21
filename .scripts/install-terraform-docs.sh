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
TERRAFORM_DOCS_VERSION=$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TERRAFORM_DOCS_ARCHIVE="terraform-docs-v${TERRAFORM_DOCS_VERSION}-${OS}-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${TERRAFORM_DOCS_ARCHIVE}" --url "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/${TERRAFORM_DOCS_ARCHIVE}"
tar xfz ${TMP_DIR}/${TERRAFORM_DOCS_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/terraform-docs ${INSTALL_DIR}/terraform-docs
chmod +x ${INSTALL_DIR}/terraform-docs
