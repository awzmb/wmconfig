#!/bin/bash
podman run --rm -it \
  -v $(pwd):/workspace -w /workspace \
  kompose:latest $@
