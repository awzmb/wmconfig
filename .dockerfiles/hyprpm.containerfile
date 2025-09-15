FROM docker.io/base/arch:latest

RUN pacman -Syu --noconfirm \
    && pacman -S --noconfirm git base-devel cmake meson cpio pkg-config g++ cargo rust python-pip \
    && pacman -Scc --noconfirm

ENTRYPOINT ["/bin/bash"]
