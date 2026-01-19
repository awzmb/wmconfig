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

#DOCKER_CREDENTIAL_GCR_VERSION=$(curl -s https://api.github.com/repos/googlecloudplatform/docker-credential-gcr/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
DOCKER_CREDENTIAL_GCR_VERSION=2.1.31
DOCKER_CREDENTIAL_GCR_ARCHIVE="docker-credential-gcr_$(uname -s | tr '[:upper:]' '[:lower:]')_${ARCH}-${DOCKER_CREDENTIAL_GCR_VERSION}.tar.gz"
curl -L --output "${TMP_DIR}/${DOCKER_CREDENTIAL_GCR_ARCHIVE}" --url "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${DOCKER_CREDENTIAL_GCR_VERSION}/${DOCKER_CREDENTIAL_GCR_ARCHIVE}"
tar xfz ${TMP_DIR}/${DOCKER_CREDENTIAL_GCR_ARCHIVE} -C ${TMP_DIR}
mv ${TMP_DIR}/docker-credential-gcr ${INSTALL_DIR}/docker-credential-gcloud
chmod +x ${INSTALL_DIR}/docker-credential-gcloud
echo $(which docker-credential-gcloud)
