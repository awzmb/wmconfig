#!/bin/sh

# The project root on your host machine.
# We use PWD to get the directory where Neovim was launched.
HOST_ROOT="${PWD}"

# The corresponding directory inside the container.
CONTAINER_ROOT="/workspace"

# Use sed to translate paths.
# 1. Neovim -> LSP: Translate host paths to container paths.
# 2. LSP -> Neovim: Translate container paths back to host paths.
# The pipe connects them all: Neovim's LSP client talks to the first sed,
# which talks to podman, which talks to the second sed, which talks back to Neovim.
sed -u "s#${HOST_ROOT}#${CONTAINER_ROOT}#g" | \
podman run \
  --rm \
  --interactive \
  --volume "${HOST_ROOT}:${CONTAINER_ROOT}:z" \
  --workdir "${CONTAINER_ROOT}" \
  docker.io/lspcontainers/rust-analyzer:latest | \
sed -u "s#${CONTAINER_ROOT}#${HOST_ROOT}#g"
