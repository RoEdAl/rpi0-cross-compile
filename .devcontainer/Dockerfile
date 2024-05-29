# syntax=docker/dockerfile:1

#
# dev-container Debain Bookworm with armhf cross compiler
#

ARG DEBIAN_FRONTEND=noninteractive
ARG ARM_GNU_TOOLCHAIN_VER=13.2.rel1

FROM scratch AS dl-task
ADD --chmod=444 http://github.com/go-task/task/releases/latest/download/task_linux_amd64.deb .

FROM scratch AS dl-arm-gnu-toolchain
ARG ARM_GNU_TOOLCHAIN_VER
ADD --chmod=444 http://armkeil.blob.core.windows.net/developer/Files/downloads/gnu/${ARM_GNU_TOOLCHAIN_VER}/binrel/arm-gnu-toolchain-${ARM_GNU_TOOLCHAIN_VER}-x86_64-arm-none-linux-gnueabihf.tar.xz .

FROM --platform=linux/arm/v6 balenalib/rpi-debian:bookworm-build AS rpi-debian
ARG DEBIAN_FRONTEND
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked <<-EOF
#!/bin/bash -e

apt-get -qq update -y
apt-get -qq upgrade -y --no-install-recommends
EOF

FROM scratch AS dl-llvm
ADD --chmod=644 https://apt.llvm.org/llvm-snapshot.gpg.key .

FROM mcr.microsoft.com/devcontainers/base:bookworm
ARG DEBIAN_FRONTEND
ARG ARM_GNU_TOOLCHAIN_VER
COPY --from=dl-llvm llvm-snapshot.gpg.key /etc/apt/trusted.gpg.d/apt.llvm.org.asc
COPY llvm.list /etc/apt/sources.list.d/llvm.list
RUN --network=none --mount=type=bind,from=dl-task,target=/mnt/download dpkg --install /mnt/download/task_linux_amd64.deb
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked <<-EOF
#!/bin/bash -e

dpkg --add-architecture armhf
apt-get -qq update -y
apt-get -qq upgrade -y --no-install-recommends
apt-get -qq install -y --no-install-recommends xz-utils qemu-user-static \
    lintian cmake ninja-build file \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf binutils-arm-linux-gnueabihf \
    clang lld \
    libsqlite3-0:armhf
EOF

USER vscode
COPY Taskfile.dist.yaml /home/vscode/Taskfile.yaml
RUN --network=none --mount=type=bind,from=rpi-debian,target=/home/vscode/cache task -d /home/vscode rpi-sysroot
RUN --network=none --mount=type=bind,from=dl-arm-gnu-toolchain,target=/home/vscode/cache task -d /home/vscode arm-gnu-toolchain-install-arm-none-linux-gnueabihf

USER root
RUN --network=none --mount=type=bind,from=rpi-debian,target=/home/vscode/cache task -d /home/vscode fix-gcc-startup-arm-linux-gnueabihf
