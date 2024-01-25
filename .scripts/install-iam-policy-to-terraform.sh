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

IAM_POLICY_TO_TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/flosell/iam-policy-json-to-terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
IAM_POLICY_TO_TERRAFORM_BINARY="iam-policy-json-to-terraform_${ARCH}"
curl -L --output "${TMP_DIR}/${IAM_POLICY_TO_TERRAFORM_BINARY}" --url "https://github.com/flosell/iam-policy-json-to-terraform/releases/download/${IAM_POLICY_TO_TERRAFORM_VERSION}/iam-policy-json-to-terraform_amd64"
mv ${TMP_DIR}/iam-policy-json-to-terraform_${ARCH} ${INSTALL_DIR}/iam-policy-json-to-terraform
chmod +x ${INSTALL_DIR}/iam-policy-json-to-terraform
