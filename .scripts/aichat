#!/bin/bash
podman run --rm -it \
  -v ${HOME}/.config/aichat:/root/.config/aichat \
  -v $(pwd):/workspace -w /workspace \
  localhost/aichat:latest $@
