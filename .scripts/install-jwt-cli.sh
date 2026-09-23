#!/bin/sh
INSTALL_DIR=${HOME}/.bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  amd64|x86_64)
    ARCH=x86_64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

JWT_VERSION=$(curl -s https://api.github.com/repos/mike-engel/jwt-cli/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
JWT_ARCHIVE="jwt-linux-musl.tar.gz"
curl -L --output "${TMP_DIR}/${JWT_ARCHIVE}" --url "https://github.com/mike-engel/jwt-cli/releases/download/${JWT_VERSION}/${JWT_ARCHIVE}"
tar xfz ${TMP_DIR}/${JWT_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/jwt ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/jwt
which jwt
