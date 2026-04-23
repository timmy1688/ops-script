#!/bin/bash
# 适用：Ubuntu 22.04/24.04 | 目标：ARM GCC 10.3 交叉编译环境
set -e

# 1. 基础配置
VER="10.3-2021.10"
URL="https://developer.arm.com/-/media/Files/downloads/gnu-rm/${VER}/gcc-arm-none-eabi-${VER}-$(uname -m)-linux.tar.bz2"
INSTALL_DIR="/opt/gcc-arm-none-eabi"

echo "--- 正在安装系统依赖 ---"
sudo apt update && sudo apt install -y wget bzip2 make cmake python3

# 2. 下载并安装工具链
if [ ! -d "$INSTALL_DIR" ]; then
    echo "--- 正在下载并解压工具链 (ARM GCC $VER) ---"
    wget -qO- "$URL" | sudo tar xj -C /opt/
    # 统一目录名，方便后续复用路径
    sudo mv /opt/gcc-arm-none-eabi-${VER} $INSTALL_DIR
fi

# 3. 永久配置环境变量 (自动去重)
if ! grep -q "$INSTALL_DIR/bin" ~/.bashrc; then
    echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> ~/.bashrc
    echo "--- 环境变量已写入 ~/.bashrc ---"
fi

# 4. 解决 Ubuntu 24.04 的 GDB 兼容性 (可选，但不占地方)
LIB_DIR="/usr/lib/$(uname -m)-linux-gnu"
[ -f "${LIB_DIR}/libncursesw.so.6" ] && [ ! -f "${LIB_DIR}/libncurses.so.5" ] && \
sudo ln -sf "${LIB_DIR}/libncursesw.so.6" "${LIB_DIR}/libncurses.so.5"

echo "--- 安装完成！请运行: source ~/.bashrc ---"
arm-none-eabi-gcc --version | head -n 1
