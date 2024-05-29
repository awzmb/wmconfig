#!/bin/sh
INSTALL_DIR=${HOME}/.bin
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  arm|armv6l|armv7l)
    ARCH=ARM
    ;;
  arm64|aarch64|armv8l)
    ARCH=ARM64
    ;;
  amd64|x86_64)
    ARCH=64bit
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
    exit 1
esac

mkdir -p ${INSTALL_DIR}

TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TRIVY_ARCHIVE="trivy_${TRIVY_VERSION}_$(uname -s)-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${TRIVY_ARCHIVE}" --url "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${TRIVY_ARCHIVE}"
tar xfz ${TMP_DIR}/${TRIVY_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/trivy ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/trivy
echo $(which trivy)
