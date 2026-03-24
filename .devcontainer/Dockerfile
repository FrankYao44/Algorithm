FROM ubuntu:22.04

# ===== 1. 基础系统与权限配置 =====
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
# 稳健版换源（国内环境建议保留，海外环境请删除下面这两行 sed）
RUN sed -i 's#http://.*.ubuntu.com#http://mirrors.aliyun.com#g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    sudo build-essential gcc g++ clang-format \
    gdb cmake make ninja-build git curl wget unzip \
    vim neovim htop tree time valgrind ca-certificates libgtest-dev \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# ===== 2. Python (算法 + 测试) =====
RUN apt-get update && apt-get install -y python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*


RUN cd /usr/src/googletest && cmake . && cmake --build . --target install


# ===== 6. 用户权限对齐 =====
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID coder \
    && useradd --uid $USER_UID --gid $USER_GID -m coder \
    && echo coder ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder

WORKDIR /workspace
ENV CC=gcc
ENV CXX=g++
USER coder

# 解决深递归爆栈问题
RUN echo 'ulimit -s unlimited' >> ~/.bashrc

CMD ["/bin/bash"]
