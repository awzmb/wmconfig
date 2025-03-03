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

#TERRAFORM_VERSION=$(curl -s https://releases.hashicorp.com/terraform/ | grep terraform/ | sed 's/<[^>]*>//g' | sed 's/terraform_//g' | tr -s \\t " " | sort -r | head -n 1 | cut -c 2-)
TERRAFORM_VERSION="1.7.5"
TERRAFORM_ARCHIVE="terraform_${TERRAFORM_VERSION}_$(uname -s | tr '[:upper:]' '[:lower:]')_${ARCH}.zip"
wget ""
curl -L --output "${TMP_DIR}/${TERRAFORM_ARCHIVE}" --url "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ARCHIVE}"
unzip ${TMP_DIR}/${TERRAFORM_ARCHIVE} -d ${TMP_DIR}
mv ${TMP_DIR}/terraform ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/terraform
which terraform
