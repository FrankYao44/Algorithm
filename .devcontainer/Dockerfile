FROM ubuntu:22.04

# ===== 1. 基础系统与权限配置 =====
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
# 稳健版换源（国内环境建议保留，海外环境请删除下面这两行 sed）
RUN sed -i 's#http://.*archive.ubuntu.com#http://mirrors.aliyun.com#g' /etc/apt/sources.list && \
    sed -i 's#http://.*security.ubuntu.com#http://mirrors.aliyun.com#g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    sudo build-essential gcc g++ clang clang-tools clang-format lld \
    gdb lldb cmake make ninja-build ccache git curl wget unzip \
    vim neovim htop tree time valgrind ca-certificates libgtest-dev \
    wget iproute2\
    && rm -rf /var/lib/apt/lists/*

# ===== 2. Python (算法 + 测试) =====
RUN apt-get update && apt-get install -y python3 python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir pytest hypothesis black ipython

# ===== 3. Node.js (使用官方节点源) =====
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install nodejs -y \
    && rm -rf /var/lib/apt/lists/*

# ===== 4. Java (OpenJDK 17) =====
RUN apt-get update && apt-get install -y openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ===== 5. 编译 GoogleTest (这一步确保 CMake 能直接 find_package) =====
RUN cd /usr/src/googletest && cmake . && cmake --build . --target install

# ===== 6. 用户权限对齐 =====
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID coder \
    && useradd --uid $USER_UID --gid $USER_GID -m coder \
    && echo coder ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder

WORKDIR /workspace
ENV CC=clang
ENV CXX=clang++
USER coder

# 解决深递归爆栈问题
RUN echo 'ulimit -s unlimited' >> ~/.bashrc

CMD ["/bin/bash"]
