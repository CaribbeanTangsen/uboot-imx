# uboot-imx 编译环境与构建指南

本项目基于 NXP i.MX 平台的 U-Boot 项目（`uboot-imx`），为 **i.MX6ULL EVK** 开发板提供了一套高度自动化的 Docker 容器化编译流程。默认使用 `mx6ull_14x14_evk_qspi1_defconfig` 配置文件进行编译。

---

## 🚀 快速开始

本项目引入了一键构建脚本 `build.sh`，仅需本地安装并启动 **Docker**，即可一键完成环境拉取、镜像构建和项目编译。

### 1. 环境准备
确保您的物理主机已安装并启动 Docker：
* **Linux/Windows**: 安装 [Docker Engine](https://docs.docker.com/engine/) / [Docker Desktop](https://www.docker.com/products/docker-desktop/)。
* **macOS (Apple Silicon / Intel)**: 安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/) 并在系统后台保持运行。

### 2. 一键编译
在项目根目录下直接运行一键编译脚本：
```bash
./build.sh
```

编译完成后，项目根目录下将直接生成您的构建产物：
* `u-boot.bin`：U-Boot 二进制映像。
* `u-boot.imx`：带 i.MX 头部信息的烧录映像（直接烧录至 SD 卡/QSPI Flash）。
* `u-boot.map`：符号映射文件。

---

## 🛠️ 一键脚本命令详解

`build.sh` 脚本非常灵活，支持以下高级编译选项：

```bash
# 1. 默认构建 (全清理 + 重新配置 + 完整编译)
./build.sh

# 2. 增量编译模式 (跳过 make mrproper 深度清理，用于微调代码后的极速构建)
./build.sh --no-clean
./build.sh -n

# 3. 强制重建 Docker 编译环境镜像 (当您更新了 Dockerfile 时使用)
./build.sh --rebuild
./build.sh -r

# 4. 查看脚本使用帮助
./build.sh --help
```

---

## 🐳 Dockerfile 编译环境设计

如果您希望手动探索或管理 Docker 环境，可以直接使用根目录下的 `Dockerfile`。

### 核心特性
* **自适应镜像加速**：基于 `ubuntu:22.04`，内置清华大学开源软件镜像源（`mirrors.tuna.tsinghua.edu.cn`）。能够自适应识别 `x86_64` 平台和 `ARM64` (Apple Silicon Mac) 平台的软件源地址，国内网络构建速度极快。
* **内置交叉编译器**：集成 Linux 标准的 `gcc-arm-linux-gnueabihf` 交叉编译器，适用于 32 位 ARM Cortex-A 架构处理器。
* **自动化配置**：自动预设系统环境变量：
  * `ARCH=arm`
  * `CROSS_COMPILE=arm-linux-gnueabihf-`
* **完整依赖链**：安装了 U-Boot 构建系统、设备树编译（DTC）、安全加密签名以及 `binman` 模块运行所需的所有开发包（如 `python3-pyelftools`, `libssl-dev`, `swig` 等）。

### 手动构建与运行命令（参考）

如果您不想使用 `build.sh`，也可以手动执行以下命令：

**1. 手动构建镜像：**
```bash
docker build -t uboot-imx-builder .
```

**2. 手动启动容器编译（使用 Bind Mount 挂载本地代码）：**
```bash
docker run --rm -v $(pwd):/workspace -it uboot-imx-builder
```

---

## 📂 项目文件变更说明

* **`Dockerfile`**：编译环境定义文件（使用国内私有云前缀及清华源加速）。
* **`.dockerignore`**：排除宿主机构建垃圾和 `.git` 历史，大幅优化 Docker 上下文传输时间。
* **`build.sh`**：自动化编译脚本，包装了复杂的 Docker 挂载和执行参数。
* **`README.md`**：本项目构建参考手册。
