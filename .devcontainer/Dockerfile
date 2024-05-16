# syntax=docker/dockerfile:1

#
# dev-container Debain Bookworm with armhf cross compiler
#

ARG DEBIAN_FRONTEND=noninteractive

FROM scratch AS dl-task
ADD --chmod=444 http://github.com/go-task/task/releases/latest/download/task_linux_amd64.deb .

FROM --platform=linux/arm/v6 balenalib/rpi-debian:bookworm-build AS rpi-debian
ARG DEBIAN_FRONTEND
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked <<-EOF
#!/bin/bash -e

apt-get -qq update -y
apt-get -qq upgrade -y --no-install-recommends
EOF

FROM mcr.microsoft.com/devcontainers/base:bookworm
ARG DEBIAN_FRONTEND
RUN --network=none --mount=type=bind,from=dl-task,target=/mnt/download dpkg --install /mnt/download/task_linux_amd64.deb
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked <<-EOF
#!/bin/bash -e

apt-get -qq update -y
apt-get -qq upgrade -y --no-install-recommends
# dpkg --add-architecture armhf
apt-get -qq install -y --no-install-recommends cmake gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf binutils-arm-linux-gnueabihf qemu-user-static
EOF

USER vscode
COPY Taskfile.dist.yaml /home/vscode/Taskfile.yaml
RUN --network=none --mount=type=bind,from=rpi-debian,target=/home/vscode/cache task -d /home/vscode rpi-sysroot

USER root
RUN --network=none --mount=type=bind,from=rpi-debian,target=/home/vscode/cache task -d /home/vscode fix-gcc-startup-arm-linux-gnueabihf
