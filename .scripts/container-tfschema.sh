#!/bin/bash
podman run --rm -it \
  -v $(pwd):/workspace -w /workspace \
  localhost/tfschema:latest $@
