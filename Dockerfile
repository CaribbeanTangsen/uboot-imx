# SPDX-License-Identifier: GPL-2.0+
#
# Dockerfile for compiling uboot-imx with mx6ull_14x14_evk_qspi1_defconfig
# Designed for high-performance and seamless multi-platform (x86_64 / Apple Silicon ARM64) compatibility.
#

# Base image using the requested prefix
FROM hub.lantusoft.com.cn/docker-hub/library/ubuntu:22.04

LABEL maintainer="Antigravity Developer Pair <antigravity@deepmind.google.com>"
LABEL description="Compilation environment for i.MX6ULL U-Boot (uboot-imx)"

# Non-interactive apt installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Configure Tsinghua University Mirror (清华源) for apt-get
# Automatically handles both x86_64 (archive/security) and ARM64 (ports) repositories
RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list && \
    sed -i 's@//security.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list && \
    sed -i 's@//ports.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list

# 2. Install compiling tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    bison \
    flex \
    libssl-dev \
    bc \
    lzop \
    device-tree-compiler \
    git \
    make \
    gcc \
    gcc-arm-linux-gnueabihf \
    libncurses-dev \
    pkg-config \
    python3 \
    python3-pyelftools \
    python3-dev \
    swig \
    u-boot-tools \
    libgnutls28-dev \
    ca-certificates \
    cpio \
    rsync \
    xxd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Set cross-compilation environment variables for ARM 32-bit (i.MX6ULL)
ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabihf-

# 4. Define workspace directory
WORKDIR /workspace

# 5. Default command: Clean, configure with the specified defconfig, and build
# This command will compile the code inside the mounted directory.
CMD ["sh", "-c", "make mrproper && make mx6ull_14x14_evk_qspi1_defconfig && make -j$(nproc)"]
