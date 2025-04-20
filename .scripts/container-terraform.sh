#!/bin/bash
podman run --rm -it \
  -v ${HOME}/.terraform.d:/root/.terraform.d \
  -v $(pwd)/.terraform:/workspace/.terraform \
  -e TF_TOKEN_app_terraform_io="${TF_TOKEN_app_terraform_io}" \
  -e TF_PLUGIN_CACHE_DIR="/root/.terraform.d/plugin-cache" \
  -e TF_DISABLE_CHECKPOINT="true" \
  -e TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE="true" \
  -v $(pwd):/workspace \
  -w /workspace \
  docker.io/hashicorp/terraform:${TERRAFORM_VERSION} $@
