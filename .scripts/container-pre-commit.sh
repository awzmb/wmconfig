#!/bin/bash
podman run --rm -it \
  -v ${HOME}/.terraform.d:/root/.terraform.d \
  -v ${HOME}/.terraformrc:/root/.terraformrc \
  -v $(pwd):/app -w /app \
  pre-commit:latest
