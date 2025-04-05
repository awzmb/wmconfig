#!/bin/sh

INSTALL_DIR=${HOME}/.go
TMP_DIR=$(mktemp -d)

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  arm|armv6l|armv7l)
    ARCH=armv6l
    ;;
  arm64|aarch64|armv8l)
    ARCH=arm64
    ;;
  amd64|x86_64)
    ARCH=amd64
    ;;
  *)
    echo "Unsupported architecture ${ARCH}"
    exit 2
esac

mkdir -p ${INSTALL_DIR}

# Install Go
mkdir -p ${INSTALL_DIR}
mkdir -p ${INSTALL_DIR}/root
GO_VERSION=$(curl -L -s --url 'https://go.dev/VERSION?m=text' | grep go)
GO_ARCHIVE="${GO_VERSION}.linux-${ARCH}.tar.gz"
curl -L --output "${TMP_DIR}/${GO_ARCHIVE}" --url "https://go.dev/dl/${GO_ARCHIVE}"
tar -C ${INSTALL_DIR} -xzf ${TMP_DIR}/${GO_ARCHIVE}

# Verify Go installation
if ! command -v go &> /dev/null; then
  echo "Go installation failed"
  exit 1
fi

# Install gopls and godocdown
GOSUMDB=sum.golang.org GOPROXY=direct go install golang.org/x/tools/gopls@latest
GOPROXY=direct go install github.com/robertkrimen/godocdown/godocdown@latest
GOPROXY=direct go install go.uber.org/mock/mockgen@latest

# Verify gopls installation
if ! command -v gopls &> /dev/null; then
  echo "gopls installation failed"
  exit 1
fi

echo "Go and gopls installed successfully"
