#!/bin/bash
podman run --rm -it \
  -v ${HOME}/.terraform.d:/root/.terraform.d \
  -v $(pwd)/.terraform:/workspace/.terraform \
  -e TF_PLUGIN_CACHE_DIR="/root/.terraform.d/plugin-cache" \
  -e TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE="true" \
  -v $(pwd):/workspace -w /workspace \
  docker.io/cytopia/terraform-docs:0.16.0 ${TERRAFORM_VERSION} $@
