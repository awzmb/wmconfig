#!/bin/bash
podman run --rm -it \
  -v ${HOME}/.terraform.d:/root/.terraform.d \
  -v ${HOME}/.terraformrc:/root/.terraformrc \
  -v $(pwd):/workspace -w /workspace \
  pre-commit:latest $@
